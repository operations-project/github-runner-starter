# This is for testing and development only.
# SSHD must be installed before running the playbook.
FROM geerlingguy/docker-${MOLECULE_DISTRO:-rockylinux8}-ansible:latest

RUN useradd runner
RUN yum install -y \
    bind-utils \
    net-tools \
    git \
    jq

# This codebase. The runner wrapper script.
COPY ./ /github-runner-starter
WORKDIR /github-runner-starter
RUN chown runner:runner . -R

# GitHub Runner code.
# Install runner to a path that won't ever be in a volume.
ENV RUNNER_PATH /usr/share/github-runner

# Install Dependencies
RUN curl https://raw.githubusercontent.com/actions/runner/refs/tags/v2.326.0/src/Misc/layoutbin/installdependencies.sh -o install-dependencies \
    && bash install-dependencies

# Run github-runner-starter script.
#RUN ./github-runner-starter --no-run --no-config --runner-path=${RUNNER_PATH}

# Change runner ownership & Switch user.
# RUN chown runner:runner ${RUNNER_PATH} -R
USER runner
