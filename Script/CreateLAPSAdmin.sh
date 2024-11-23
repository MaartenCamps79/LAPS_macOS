#!/bin/bash

# Log File location
LOG_FILE="/var/log/hidden_admin_setup.log"
LOG_DIR="/var/log" 

# Log Function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Start script voor het aanmaken van een verborgen admin-account."

# Variables
USERNAME="LAPS_Admin"
KEYVAULT_NAME="{Name of the Key Vault}V"
AZURE_TENANT_ID="{Tenant ID}"
AZURE_CLIENT_ID="{Secret ID}"
AZURE_CLIENT_SECRET="{Secret}"
PASSWORD_LENGTH=8

# Check if Homebrew is installed
if ! command -v brew &> /dev/null
then
    log "Homebrew is niet geïnstalleerd. Installeren van Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install jq using Homebrew
brew install jq

# Verify the installation
jq --version

log "jq is successful installed."


# Check if users exists
if id "$USERNAME" &>/dev/null; then
    log "Gebruiker '$USERNAME' bestaat al. Geen actie nodig."
    exit 0
fi

# Generate random password
PASSWORD=$(openssl rand -base64 $PASSWORD_LENGTH)
log "Nieuw wachtwoord gegenereerd voor gebruiker '$USERNAME'."

# generate a unique UniqueID
log "Generate unique UniqueID."
NEW_UID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1 | awk '{print $1+42}')

# Check if id exists
if dscl . -list /Users UniqueID | awk '{print $2}' | grep -q "^$NEW_UID$"; then
    log "Error: Generated ID $NEW_UID already in use."
    exit 1
fi

log "UniqueID $NEW_UID is available"

# Maak een nieuwe gebruiker aan
log "Create new admin with name '$USERNAME'."
sudo dscl . -create /Users/$USERNAME
sudo dscl . -create /Users/$USERNAME UserShell /bin/bash
sudo dscl . -create /Users/$USERNAME RealName "LAPS Admin"
sudo dscl . -create /Users/$USERNAME UniqueID "$NEW_UID"
sudo dscl . -create /Users/$USERNAME PrimaryGroupID 80
sudo dscl . -create /Users/$USERNAME NFSHomeDirectory /Users/$USERNAME
sudo dscl . -passwd /Users/$USERNAME "$PASSWORD"
sudo dscl . -append /Groups/admin GroupMembership $USERNAME

log "User '$USERNAME' successfully created."

# Hide User
log "Hide '$USERNAME' from login list."
sudo defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array-add $USERNAME

log "Gebruiker '$USERNAME' is verborgen in de loginlijst."

# Access toke to Azure
log "Verkrijg Azure toegangstoken."
ACCESS_TOKEN=$(curl -s -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=$AZURE_CLIENT_ID&client_secret=$AZURE_CLIENT_SECRET&resource=https://vault.azure.net" \
    "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/token" | jq -r '.access_token')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
    log "Error: Token obtain error"
    exit 1
fi

log "Azure token has successfully been obtained."

# Check if password is stored in KeyVault
VAULT_URL="https://$KEYVAULT_NAME.vault.azure.net"
COMPUTER_NAME=$(scutil --get ComputerName)

log "Check if password is stored in keyvault for $COMPUTER_NAME."
EXISTING_SECRET=$(curl -s -X GET \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "$VAULT_URL/secrets/$COMPUTER_NAME?api-version=7.3" | jq -r '.value')

if [[ -n "$EXISTING_SECRET" && "$EXISTING_SECRET" != "null" ]]; then
    log "A password found in the keyvault $COMPUTER_NAME. This will be overwritten."
else
    log "No password found in the keyvault $COMPUTER_NAME. A new secret will be created."
fi

# Save password in keyvault
RESPONSE=$(curl -s -X PUT \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"value\": \"$PASSWORD\", \"attributes\": {\"enabled\": true}}" \
    "$VAULT_URL/secrets/$COMPUTER_NAME?api-version=7.3")

if echo "$RESPONSE" | jq -e '.id' &>/dev/null; then
    log "Password sucessfully saved for '$COMPUTER_NAME'."
else
    log "Error: saving password Response: $RESPONSE"
    exit 1
fi



log "Scripts succesfully ended. Hidden admin-account '$USERNAME' has been created with password stored in KeyVault."
