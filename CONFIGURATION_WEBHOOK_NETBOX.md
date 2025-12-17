# Configuration Webhook Netbox pour Déclencher Semaphore

Ce guide explique comment configurer Netbox pour déclencher automatiquement la création de VMs dans Proxmox via Semaphore lorsqu'une VM est créée dans Netbox.

## Architecture

```
Netbox (Création VM) 
  → Event Rule (déclenchement)
  → Webhook (POST)
  → Semaphore API (déclenchement du template)
  → Ansible Playbook
  → Proxmox (Création VM)
```

## Prérequis

1. Semaphore doit être accessible depuis Netbox (même réseau ou routage configuré)
2. Un token d'API Semaphore doit être créé
3. Le template de tâche "Deploy VMs from Netbox" doit exister dans Semaphore

## Étape 1 : Créer un Token API dans Semaphore

1. Connectez-vous à Semaphore (http://votre-serveur:3000)
2. Allez dans **Settings** > **Access Keys**
3. Cliquez sur **Add Key**
4. Donnez un nom (ex: "Netbox Webhook")
5. Copiez le token généré (vous en aurez besoin pour le webhook)

## Étape 2 : Obtenir l'ID du Template dans Semaphore

1. Dans Semaphore, allez dans **Templates**
2. Ouvrez le template "Deploy VMs from Netbox"
3. Notez l'ID du template dans l'URL (ex: `template/2` = ID 2)
4. Notez également l'ID du projet (ex: `project/1` = ID 1)

## Étape 3 : Créer le Webhook dans Netbox

1. Connectez-vous à Netbox
2. Allez dans **Extras** > **Webhooks** (ou **Intégrations** > **Webhooks** selon la version)
3. Cliquez sur **Add**
4. Configurez le webhook :
   - **Name** : `Semaphore - Deploy VM to Proxmox`
   - **Content Types** : Sélectionnez `Virtualization > Virtual Machine`
   - **URL** : `http://<IP_SEMAPHORE>:3000/api/project/<PROJECT_ID>/template/<TEMPLATE_ID>`
     - Remplacez `<IP_SEMAPHORE>` par l'IP du serveur Semaphore (ex: `10.0.20.50`)
     - Remplacez `<PROJECT_ID>` par l'ID du projet (ex: `1`)
     - Remplacez `<TEMPLATE_ID>` par l'ID du template (ex: `2`)
   - **HTTP Method** : `POST`
   - **HTTP Content Type** : `application/json`
   - **Additional Headers** : Ajoutez :
     ```
     Authorization: Bearer <SEMAPHORE_API_TOKEN>
     ```
     Remplacez `<SEMAPHORE_API_TOKEN>` par le token créé à l'étape 1
   - **Body Template** : Utilisez le template Jinja2 suivant :
     ```json
     {
       "debug": false,
       "dry_run": false,
       "diff": false,
       "extra_vars": {
         "vm_name": "{{ data['name'] }}",
         "netbox_url": "https://netbox.cesi.local",
         "netbox_token": "<NETBOX_API_TOKEN>",
         "proxmox_api_host": "10.0.20.50",
         "proxmox_api_user": "root@pam",
         "proxmox_api_token_id": "One",
         "proxmox_api_token_secret": "<PROXMOX_TOKEN_SECRET>"
       }
     }
     ```
     **Important** : Remplacez :
     - `<TEMPLATE_ID>` par l'ID du template
     - `<NETBOX_API_TOKEN>` par votre token Netbox
     - `<PROXMOX_TOKEN_SECRET>` par votre secret Proxmox
   - **Enabled** : Cochez la case
5. Cliquez sur **Save**

## Étape 4 : Créer l'Event Rule dans Netbox

1. Dans Netbox, allez dans **Extras** > **Event Rules** (ou **Intégrations** > **Event Rules**)
2. Cliquez sur **Add**
3. Configurez la règle :
   - **Name** : `Trigger Proxmox VM Creation`
   - **Content Type** : `Virtualization > Virtual Machine`
   - **Event Types** : Cochez uniquement `created` (création)
   - **Conditions** (optionnel) : Vous pouvez ajouter des conditions, par exemple :
     - `status == "active"` : Seulement pour les VMs actives
     - `cluster.name == "proxmox-cluster"` : Seulement pour le cluster Proxmox
   - **Action Type** : `Webhook`
   - **Webhook** : Sélectionnez le webhook créé à l'étape 3
   - **Enabled** : Cochez la case
4. Cliquez sur **Save**

## Étape 5 : Tester la Configuration

1. Dans Netbox, créez une nouvelle VM virtuelle
2. Vérifiez dans Semaphore que la tâche a été déclenchée automatiquement
3. Vérifiez dans Proxmox que la VM a été créée

## Dépannage

### Le webhook ne se déclenche pas

1. Vérifiez que l'Event Rule est activée
2. Vérifiez que le Content Type correspond
3. Vérifiez que l'Event Type "created" est coché
4. Vérifiez les logs de Netbox pour les erreurs

### La tâche Semaphore échoue

1. Vérifiez que le token API Semaphore est correct
2. Vérifiez que l'URL du webhook est correcte
3. Vérifiez que les variables `extra_vars` sont correctement définies
4. Vérifiez les logs de Semaphore

### La VM n'est pas créée dans Proxmox

1. Vérifiez que le playbook s'exécute correctement
2. Vérifiez que les credentials Proxmox sont corrects
3. Vérifiez que le nom de la VM dans Netbox correspond aux attentes

## Notes Importantes

- **Sécurité** : Pour la production, utilisez HTTPS et sécurisez les tokens API
- **Variables** : Les tokens dans le Body Template sont en clair. Pour plus de sécurité, utilisez les secrets de Semaphore
- **Filtrage** : Utilisez les conditions dans l'Event Rule pour ne déclencher que les VMs pertinentes
- **Idempotence** : Le playbook est idempotent, donc relancer une tâche pour une VM existante ne créera pas de doublon
