# Workaround old docker images with incorrect $HOME
# check https://github.com/docker/docker/issues/2968 for details
if [ "${HOME}" = "/" ]
then
  export HOME=$(getent passwd $(id -un) | cut -d: -f6)
fi

mkdir -p ~/.ssh

echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
' >> ~/.ssh/known_hosts

(umask 077; touch ~/.ssh/id_rsa)
chmod 0600 ~/.ssh/id_rsa
(cat <<EOF > ~/.ssh/id_rsa
$CHECKOUT_KEY
EOF
)

# use git+ssh instead of https
git config --global url."ssh://git@github.com".insteadOf "https://github.com" || true
git config --global gc.auto 0 || true

if [ -e $HOME/project/.git ]
then
  cd $HOME/project
  git remote set-url origin "$CIRCLE_REPOSITORY_URL" || true
else
  mkdir -p $HOME/project
  cd $HOME/project
  if [ -n "$CIRCLE_BRANCH" ]
  then
    if [ -n "$CIRCLE_PR_NUMBER" ]
    then
      git clone --depth=1 --recurse-submodules --shallow-submodules "$CIRCLE_REPOSITORY_URL" .
    else
      git clone --depth=1 --recurse-submodules --shallow-submodules --branch="$CIRCLE_BRANCH" "$CIRCLE_REPOSITORY_URL" .
    fi
  else
    git clone --recurse-submodules --shallow-submodules "$CIRCLE_REPOSITORY_URL" .
  fi
fi

if [ -n "$CIRCLE_TAG" ]
then
  git fetch origin --depth=1 "refs/tags/${CIRCLE_TAG}"
else
  if [ -n "$CIRCLE_PR_NUMBER" ]
  then
    git fetch origin --depth=1 "+refs/$CIRCLE_BRANCH/head"
  fi
fi


if [ -n "$CIRCLE_TAG" ]
then
  git reset --hard "$CIRCLE_SHA1"
  git checkout -q --recurse-submodules "$CIRCLE_TAG"
elif [ -n "$CIRCLE_BRANCH" ]
then
  git reset --hard "$CIRCLE_SHA1"
  git checkout -q --recurse-submodules -B "$CIRCLE_BRANCH"
  git tag -a -m "Circle CI build" init
fi

git reset --hard "$CIRCLE_SHA1"
git submodule update --init
