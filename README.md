## Introduction

In the absence of a Local Administrator Password Solution (LAPS) for macOS within Microsoft Intune, this project was conceived to provide a secure and automated alternative. The `CreateLAPSAdmin.sh` script addresses the need for a robust solution to manage local admin accounts on macOS devices, ensuring that each account is created with a unique, randomized password and stored securely in Azure KeyVault. This approach enhances security and simplifies the management of local admin accounts across multiple macOS.

[LapsFormacOS]()

## Summary

The `CreateLAPSAdmin.sh` script is designed to create a Local Administrator Password Solution (LAPS) admin account on macOS systems. This script automates the process of setting up a secure local admin account with a randomized passwordwhich is stored in a Azure KeyVault. It ensures that the local admin account adheres to security best practices, reducing the risk of unauthorized access.

Key features of the script include:
- Creation of a local admin account with a unique, randomized password.
- Secure storage and management of the admin password.
- Compatibility with macOS environments.
- Automation to streamline the setup process and enhance security.

This script is particularly useful for IT administrators who need to manage multiple macOS devices and ensure that each has a secure local admin account.

 ## This function requires the following prerequisites:
 
 * 1. **Key Vault**: Ensure you have an Azure Key Vault set up to store and manage secrets.
 * 2. **App Registration**: Register an application in Azure AD with the correct permissions to access the Key Vault.
 *    - Required permissions: `Key Vault Secrets User` or `Key Vault Secrets Officer`.
 * 3. **Homebrew**: Install Homebrew package manager on your system. You can install it from [Homebrew's official website](https://brew.sh/). This is already covered in the script
 * 4. **jq**: Install `jq` for processing JSON data. You can install it using Homebrew:
 *    brew install jq. This is already taken care of in the script

## Deployment and Scheduling in Intune

To deploy and schedule the `CreateLAPSAdmin.sh` script in Microsoft Intune, follow these steps:

1. **Upload the Script to Intune**:
    - Navigate to the Microsoft Endpoint Manager admin center.
    - Go to **Devices** > **Scripts** > **Add**.
    - Select **macOS** as the platform.
    - Upload the `CreateLAPSAdmin.sh` script.
    - Configure the script settings as needed and assign it to the appropriate device groups.

2. **Schedule the Script to Run Weekly**:
    - In the script settings, configure the script to run on a recurring schedule.
    - Set the frequency to **Weekly** to ensure the script runs every week.
    - This ensures that if the hidden admin account is deleted, it will be recreated within a week.

3. **Monitor Script Execution**:
    - Use the Intune reporting features to monitor the execution of the script.
    - Ensure that the script runs successfully on all targeted devices.

By scheduling the `CreateLAPSAdmin.sh` script to run weekly, you can ensure that the hidden admin account is consistently recreated, maintaining the security and management of local admin accounts on your macOS devices.
