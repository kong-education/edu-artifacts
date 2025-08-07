# edu-artifacts
This is the public-facing repo for Lab Artifacts. Using GitHub Actions, artifacts and user scripts are automatically synced from the courses repository:

- edu-strigo-courses/COURSE/artifacts/ -> edu-artifacts/COURSE/artifacts
- edu-strigo-courses/COURSE/scripts ->  edu-artifacts/COURSE/scripts

startup.sh and post_startup.sh are excluded from the sync as those are system scripts.

Github Action Workflow: https://github.com/kong-education/edu-strigo-courses/blob/main/.github/workflows/sync-artifacts.yaml
It is triggered when changes are made to the main branch of the courses repo

SSH Key Process:
- Generation: `ssh-keygen -t ed25519 -C "gh-action@kong" -f edu-artifacts-deploy-key -N ""`
- GitHub → edu-artifacts → Settings → Deploy Keys → Add Public Key (write access)
- GitHub → edu-strigo-courses → Settings → Secrets → New repository secret
    Name: ARTIFACTS_REPO_KEY
    Value: Private Key
