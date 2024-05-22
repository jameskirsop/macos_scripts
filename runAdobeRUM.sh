#!/bin/zsh

# Requires SwiftDialog to be installed
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
customRumLog="/Library/Logs/CustomAdobeRUMLog.log"
adobeIcon="https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/ec8f9376e3f5b7dd6c86a580ba9a79b7_c8hbHBZwjD.png"
dialogBanner="/Library/Application Support/SwiftDialog/dialog_banner_small.png"
supportText="Please contact the helpdesk for further assistance"
rumPath="/usr/local/bin/RemoteUpdateManager"

dialogDefaults+=(
    --bannerimage "$dialogBanner"
    --moveable 
    --messagealignment left
    --icon "$adobeIcon"
)

# convenience function to run a command as the current user (https://scriptingosx.com/2020/08/running-a-command-as-another-user/)
# usage:
#   runAsUser command arguments...
runAsUser() {  
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser $(id -u "$currentUser") sudo -u "$currentUser" "$@"
  else
    echo "no user logged in"
  fi
}


function quit_apps_and_update {
    runAsUser osascript -e 'quit app "Photoshop"'
    runAsUser osascript -e 'quit app "Illustrator"'
    runAsUser osascript -e 'quit app "InDesign"'
    runAsUser osascript -e 'quit app "Adobe Acrobat"'
    runAsUser osascript -e 'quit app "Acrobat Reader"'
    runAsUser osascript -e 'quit app "Adobe Lightroom Classic"'
    runAsUser osascript -e 'quit app "Adobe Lightroom"'
    runAsUser osascript -e 'quit app "Bridge"'
    runAsUser osascript -e 'quit app "InCopy"'
    runAsUser osascript -e 'quit app "Camera Raw"'
    runAsUser osascript -e 'quit app "Premiere Rush"'
    runAsUser osascript -e 'quit app "Premiere Pro"'
    runAsUser osascript -e 'quit app "After Effects"'
    runAsUser osascript -e 'quit app "Audition"'
    runAsUser osascript -e 'quit app "Animate"'
    runAsUser osascript -e 'quit app "Character Animator"'
    runAsUser osascript -e 'quit app "Media Encoder"'
    runAsUser osascript -e 'quit app "Dreamweaver"'

    /usr/local/bin/RemoteUpdateManager &> $customRumLog
    rumRealReturnCode=${"$(grep -i "exiting with Return Code" "$customRumLog")":(-2):1}
    if [ $rumRealReturnCode -eq 0 ]; then
        echo "Updates installed or no updates needed." 
        /usr/local/bin/dialog --title 'Adobe Updates Completed' \
        --message "Thanks for allowing Adobe apps to update.  \n\nYou can now open resume using your applications." \
        --button1text "Ok!" \
        "${dialogDefaults[@]}"
    else
        /usr/local/bin/dialog --title 'Adobe Updates Failed' \
        --message "Some Adobe apps failed to update.  \n\n${supportText}." \
        --button1text "Ok!" \
        "${dialogDefaults[@]}"
        echo "On a 2nd attempt, some updates failed to install." 
        exit 1
    fi
}

echo "Beginning Adobe RUM Script"

timestamp=$(date +"%Y-%m-%d %T")
# log the function call
echo "$timestamp - Configuring log file: $customRumLog" >> "$customRumLog"

if [ -f $rumPath ]; then
    #Attempt Updates
    /usr/local/bin/RemoteUpdateManager &> $customRumLog
    rumRealReturnCode=${"$(grep -i "exiting with Return Code" "$customRumLog")":(-2):1}
    if [ $rumRealReturnCode -eq 0 ]; then
        echo "Updates installed or no updates needed." 
    elif [ $rumRealReturnCode -eq 2 ]; then
        if [ "$loggedInUser" != "root" ]; then
            if ! command -v dialog > /dev/null 2>&1; then
                echo "Dialog is not installed."
                exit 1
            fi
            RUM_UPDATES=$(sudo /usr/local/bin/RemoteUpdateManager --action=list)
            ACRO_UPDATE_COUNT=$(echo "$RUM_UPDATES" | awk '/Following Acrobat\/Reader updates are applicable on the system/{flag=1; next} /\*\*\*\*\*\*\*\*\*\*\*/{flag=0} flag' | grep -c '^')
            CC_UPDATE_COUNT=$(echo "$RUM_UPDATES" | awk '/Following Updates are applicable on the system/{flag=1; next} /\*\*\*\*\*\*\*\*\*\*\*/{flag=0} flag' | grep -c '^')

            secho=$(awk '/Following Updates failed to Install/{flag=1} /\*\*\*\*\*\*\*\*\*\*\*/{flag=0} flag' "$customRumLog" | sed 's/Following Updates failed to Install :/the following updates failed to install/g' \
                | sed 's/ACR/Camera Raw/g' \
                | sed 's/AEFT/After Effects/g' \
                | sed 's/AME/Media Encoder/g' \
                | sed 's/AUDT/Audition/g' \
                | sed 's/FLPR/Animate/g' \
                | sed 's/ILST/Illustrator/g' \
                | sed 's/MUSE/Muse/g' \
                | sed 's/PHSP/Photoshop/g' \
                | sed 's/PRLD/Prelude/g' \
                | sed 's/SPRK/XD/g' \
                | sed 's/KBRG/Bridge/g' \
                | sed 's/AICY/InCopy/g' \
                | sed 's/ANMLBETA/Character Animator Beta/g' \
                | sed 's/DRWV/Dreamweaver/g' \
                | sed 's/IDSN/InDesign/g' \
                | sed 's/PPRO/Premiere Pro/g' \
                | sed 's/LTRM/Lightroom Classic/g' \
                | sed 's/LRCC/Lightroom/g' \
                | sed 's/CHAR/Character Animator/g' \
                | sed 's/SBSTA/Substance Alchemist/g' \
                | sed 's/SBSTD/Substance Designer/g' \
                | sed 's/SBSTP/Substance Painter/g' \
                | sed 's/ESHR/Dimension/g' \
                | sed 's/RUSH/Premiere Rush/g' \
                | sed 's/\\/\\\\/g' \
                | sed 's/[\(\)\.\*\[\]]/\\&/g' \
                | sed 's/^[[:blank:]]*//g' \
                | sed 's/)$//g' \
                | sed 's/^(//g' \
                | awk 'BEGIN { RS="" } { gsub(/\n/, "  \n * "); print }' )
            /usr/local/bin/dialog --title 'Adobe Updates Required' \
            --height "600" \
            --message "We tried to silently perform some Adobe updates however ${secho}.  \n\nPlease choose an option below to proceed.  \n\nIf you choose to 'Quit Apps and Update', all Adobe applications will Quit and another dialog will appear when the updates have completed." \
            --button1text "Quit Apps and Update" \
            --button2text "Delay Update" \
            "${dialogDefaults[@]}"

            if [ $? -eq 0 ]; then
                echo 'Qutting apps and attempting updates!'
                quit_apps_and_update
            else
                echo 'User declined updates'
            fi
        fi
    else
        # Trigger an alert to indicate that RUM / Adobe Application Updater might be broken
        printf 'Adobe Exit Code: %d\n' $rumRealReturnCode
        echo "Adobe Remote Update Manager might be broken!"
        exit 1
    fi
else
    echo "Adobe RUM not present at ${rumPath}"
    exit 1
fi