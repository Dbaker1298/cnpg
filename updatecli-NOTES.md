# NOTES for Updatecli tasks

https://www.updatecli.io/docs/prologue/quick-start/

- install binary; https://github.com/updatecli/updatecli/releases/tag/v0.100.0
- verify checksum; `sha256sum updatecli_amd64.deb && cat checksums.txt| grep 'amd64.deb'`
- We need a "Data file" that we want to update if needed. e.g., `Chart.yaml`
- `updatecli` needs at least one manifest to know what "update pipeline to apply."
  - **Source** definition of where info is coming from. `cloudnative-pg` releases.
  - **Target** definition describes what we want to update based on **source**. `dependencies[0].version`
  - **Condition** definition defined conditions required to update the **target**. Test that the image does exist upstream.

### Updatecli Pipeline

**Source** --> **Condition** --> **Target** --> **Action**

Source, Condtion, and Target behave differently based on the **plugin** used, which is defined by **"kind"**.

`updatecli diff --config updatecli.d/cnpg-updatecli.yaml `
`updatecli apply --config updatecli.d/cnpg-updatecli.yaml`

`helm plugin install https://github.com/d2iq-labs/helm-list-images`
`list-images CHART|RELEASE [flags]`

➜  cnpg-opetator git:(main) ✗ `helm list-images .`
**ghcr.io/cloudnative-pg/cloudnative-pg:1.25.1**
➜  cnpg-opetator git:(main) ✗ `pwd`
/home/david/projects/cnpg-operator/cnpg/**.github/package-management/cnpg-opetator**

---

---
name: Bump OpenTelemetry-Collector chart version

pipelineid: "opentelemetry-collector"

scms:
  default:
    kind: github
    spec:
      user: "{{ .github.user }}"
      email: "{{ .github.email }}"
      owner: "{{ .github.owner }}"
      repository: "{{ .github.repository }}"
      token: "{{ requiredEnv .github.token }}"
      username: "{{ .github.username }}"
      branch: "{{ .github.branch }}"

sources:
  chartLatestRelease:
    kind: helmchart
    spec:
      url: https://open-telemetry.github.io/opentelemetry-helm-charts
      name: opentelemetry-collector

targets:
  chartVersion:
    sourceid: chartLatestRelease
    name: Update Chart Version for OpenTelemetry Collector to {{ source "chartLatestRelease" }}
    kind: file
    spec:
      file: opentelemetry-collector/deploy.sh
      matchpattern: "CHART_VERSION=.*"
      replacepattern: 'CHART_VERSION={{ source "chartLatestRelease" }}'
    scmid: default

actions:
  default:
    kind: github/pullrequest
    scmid: default
    title: Bump OpenTelemetry Collector chart version to {{ source "chartLatestRelease" }}
    spec:
      labels:
        - dependencies
        - observability
