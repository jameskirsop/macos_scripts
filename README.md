# macos_scripts

This is a collection of scripts I've written (often with the help of those in the Mac Admins community) for managing macOS endpoints.

### runAdobeRUM.sh
Using a combination of [Adobe RUM](https://helpx.adobe.com/au/enterprise/using/using-remote-update-manager.html) and [SwiftDialog](https://github.com/swiftDialog/swiftDialog), this tries to silently install available updates for Adobe software and prompts the user to quit applications if RUM is unable to complete the updates successfully.