# Déploiement Ansible

Ansible est l'unique moteur d'orchestration du homelab. Docker Compose reste responsable de la définition des applications.

## Premier démarrage

Après installation de Raspberry Pi OS Lite 64 bits et activation de SSH :

```bash
sudo apt update
sudo apt install -y ansible git
```

Puis exécuter la branche à tester :

```bash
sudo ansible-pull \
  -U https://github.com/bvssteel/pi-homelab.git \
  -C v0.1-host-config \
  -i 'localhost,' \
  -c local \
  -e homelab_repo_branch=v0.1-host-config \
  ansible/site.yml
```

Après fusion, remplacer les deux occurrences de `v0.1-host-config` par `main`.

## Pourquoi la branche apparaît deux fois

- `-C` sélectionne la branche utilisée par `ansible-pull` pour exécuter le playbook.
- `homelab_repo_branch` sélectionne la branche synchronisée durablement dans `/opt/pi-homelab` et utilisée par Docker Compose.

Les deux valeurs doivent normalement être identiques lors d'un test.

## Vérification d'idempotence

Exécuter deux fois la même commande. La seconde exécution doit produire le moins de changements possible et ne doit ni recréer inutilement les conteneurs ni modifier les fichiers déjà conformes.

## Authentification Tailscale

L'installation et le démarrage du daemon sont déclaratifs. La première authentification reste une action explicite :

```bash
sudo tailscale up
```

L'utilisation future d'une clé d'authentification chiffrée pourra automatiser cette étape sans exposer de secret dans Git.
