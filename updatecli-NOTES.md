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

`manifest.yaml`
