# Docker GitHub runner (Ubuntu 22.04)

An ephemeral GitHub action runner in a Docker container.

## Requirements
* [Sysbox](https://github.com/nestybox/sysbox)
* Docker (also works with
  [k8s and sysbox](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/install-k8s.md))

## Getting Started

See [docker-compose.yml.example](docker-compose.yml.example) for an
example docker compose configuration.

### Kubernetes Example

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: onvox-runner
  labels:
    app: github-runners-onvox
spec:
  replicas: 3
  selector:
    matchLabels:
      app: github-runners-onvox
  template:
    metadata:
      labels:
        app: github-runners-onvox
      annotations:
        io.kubernetes.cri-o.userns-mode: "auto:size=65536"
    spec:
      runtimeClassName: sysbox-runc
      restartPolicy: Always
      containers:
        - name: docker-ubuntu2204-runner
          image: ghcr.io/onvox/docker-ubuntu2204-runner:2.315.0
          env:
            - name: GITHUB_ORG
              value: MyOrg
            - name: GITHUB_TOKEN
              valueFrom:
                secretKeyRef:
                  name: github-runner-onvox
                  key: github-token
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: RUNNER_NAME
              value: "$(POD_NAME)"
```
