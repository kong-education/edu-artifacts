# edu-artifacts

Public files for Kong Academy courses: configuration files, specs, and scripts that learners download during labs and self-paced courses.

## Layout

Each course has its own folder, named after its course code:

```
COURSE/
├── artifacts/   configuration files, specs, and other course files
└── scripts/     helper scripts
```

## Downloading files

Courses link to files through their raw URL:

```
https://raw.githubusercontent.com/kong-education/edu-artifacts/<ref>/<COURSE>/artifacts/<file>
```

For example, from a terminal:

```bash
curl -fsSLO https://raw.githubusercontent.com/kong-education/edu-artifacts/main/KGLL-115/artifacts/proxy-cache.yaml
```

`<ref>` is a branch or tag. Course materials may pin a tag so the files they reference don't change after publication.

## How files get here

Don't edit course folders in this repo directly. They are published from the private course repository [kong-education/edu-instruqt-courses](https://github.com/kong-education/edu-instruqt-courses) by the [sync-artifacts](https://github.com/kong-education/edu-instruqt-courses/blob/main/.github/workflows/sync-artifacts.yaml) GitHub Actions workflow:

- The workflow runs **manually**: in edu-instruqt-courses, open **Actions** > **Mirror Artifacts/Scripts to Public Repo** > **Run workflow**, and choose the branch to publish from (normally `main`).
- Only files listed in a course's `manifests/pubclone.yaml` are published, one path per line, relative to the course folder.
- For each course with a manifest, the course folder here is replaced with exactly the listed files. Anything else in that folder, including direct edits, is removed on the next run.
- Courses without a manifest are skipped, and their folders here are left as they are.

To publish files for a course, add them under `COURSE/artifacts/` or `COURSE/scripts/` in edu-instruqt-courses, list them in `COURSE/manifests/pubclone.yaml`, and run the workflow.

## Legacy course folders

`KKLL-209`, `KKLL-241`, `KMLL-205`, and `KMLL-206` were published from the retired edu-strigo-courses repository. They stay available as they are and are no longer updated, unless a manifest for the course is added to edu-instruqt-courses.

## License

See [LICENSE](LICENSE).
