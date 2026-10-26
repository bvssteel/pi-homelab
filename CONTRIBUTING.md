# Contributing

Keep changes small and focused. This baseline supports Ubuntu Server 24.04 ARM64 on Pi 5,
controlled from WSL with Ansible. Application deployment remains separate for now.

- Use Ansible modules instead of Bash scripts or `shell` tasks.
- Pin reusable role versions in `requirements.yml`.
- Preserve the existing application state layout.
- Keep credentials, private keys and local inventory out of Git.
- Do not add services, hardening or storage policies without a separate decision.

## Validate Ansible

```console
ansible-galaxy role install -r requirements.yml
ansible-playbook -i inventory/hosts.example.yml site.yml --syntax-check
ansible-lint site.yml roles/host_base
```

`ansible-lint` is a development tool to install on the control machine if needed.
After static checks, validate a first run and rerun on the actual Pi before claiming
hardware compatibility or idempotence. Never run these playbooks on the control machine
with a local connection: they are meant to configure the explicitly inventoried Pi.
