# This is for testing and development only.
# SSHD must be installed before running the playbook.
FROM geerlingguy/docker-${MOLECULE_DISTRO:-rockylinux8}-ansible:latest

RUN useradd runner
RUN yum install -y \
    git \
    jq

# This codebase. The runner wrapper script.
COPY ./ /github-runner
WORKDIR /github-runner
RUN chown runner:runner . -R

# GitHub Runner code.
# Install runner to a path that won't ever be in a volume.
ENV RUNNER_PATH /usr/share/github-runner
RUN mkdir $RUNNER_PATH && chown runner:runner $RUNNER_PATH -R

USER runner
RUN ./github-runner --no-run --no-config \
       --runner-path=${RUNNER_PATH}