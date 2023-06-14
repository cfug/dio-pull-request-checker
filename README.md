# action for check pr

Check [dio-wiki](https://github.com/cfug/dio/wiki/Releasing-a-new-version-of-packages#before-start) to know changelog format.

## Setup action

```yaml
name: "Check pull request"

on:
  pull_request:
    types:
      - ready_for_review
      - converted_to_draft
      - reopened
      - opened
      - unlocked
      - synchronize
jobs:  
  check-pull-request-changelog:
    if: github.event_name == 'pull_request' && github.event.pull_request.draft == false && github.event.pull_request.merged == false
    runs-on: ubuntu-latest
    steps:
    - uses: cfug/dio-pull-request-checker@v1
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
permissions:
  pull-requests: write
```
