# Filesystem BBR

A BOSH release for BBR script that allows to backup arbitrary folder.

## Usage

Add to `releases` in deployment manifest
```YAML
releases:
- name: filesystem-bbr-boshrelease
  version: 1.3.8
  url: git+https://github.com/grapeup/filesystem-bbr-boshrelease
```

Add jobs
```YAML
  - name: filesystem-backup-restorer
    release: filesystem-bbr-boshrelease
    properties:
      backup_path: /var/vcap/store/prometheus2/snapshot/*
      restore_path: /var/vcap/store/prometheus2
      backup_name: prometheus2
      pre_backup_script: "curl -XPOST http://$URL:9090/api/v1/admin/tsdb/snapshot?skip_head=true"
      post_backup_script: "rm -rf /var/vcap/store/prometheus2/snapshots/*"
      pre_restore_script: "rm -rf /var/vcap/store/prometheus2/*"
      post_restore_script: ""

  - name: job-lock
    release: filesystem-bbr-boshrelease
    properties:
      lock:
        monit_job:
        - prometheus2
        pid_path:
        - /var/vcap/sys/run/prometheus2/prometheus.pid
        skip_backup_lock: "false"
```

```YAML
---
- type: replace
  path: /instance_groups/name=prometheus2/jobs/name=filesystem-backup-restorer?
  value:
    name: filesystem-backup-restorer
    release: filesystem-bbr-boshrelease
    properties:
      backup_path: "/var/vcap/store/prometheus2/snapshots/*"
      restore_path: /var/vcap/store/prometheus2
      backup_name: prometheus2
      pre_backup_script: "curl -XPOST http://127.0.0.1:9090/api/v1/admin/tsdb/snapshot?skip_head=true"
      post_backup_script: "rm -rf /var/vcap/store/prometheus2/snapshots/*"
      pre_restore_script: "rm -rf /var/vcap/store/prometheus2/*"
      post_restore_script: ""

- type: replace
  path: /instance_groups/name=prometheus2/jobs/name=job-lock?
  value:
    name: job-lock
    release: filesystem-bbr-boshrelease
    properties:
      lock:
        monit_job:
        - prometheus2
        pid_path:
        - /var/vcap/sys/run/prometheus2/pid
        skip_backup_lock: true

- type: replace
  path: /releases/name=filesystem-bbr-boshrelease?
  value:
    name: filesystem-bbr-boshrelease
    version: 1.3.8
    url: git+https://github.com/grapeup/filesystem-bbr-boshrelease
```

