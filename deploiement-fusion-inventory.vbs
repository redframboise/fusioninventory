'  Guide pdf d'accompagnement : (soon)
'
'  Voici les auteurs du script.
'  ------------------------------------------------------------------------
'  @auteur(s) Benjamin Accary <meldrone@orange.fr>
'             Christophe Pujol <chpujol@gmail.com>
'             Marc Caissial <marc.caissial@zenitique.fr>
'             Tomas Abad <tabadgp@gmail.com>
'             Wanderlei Hüttel <wanderlei.huttel@gmail.com>
'  ------------------------------------------------------------------------

Option Explicit
Dim Force, Verbose
Dim Setup, SetupArchitecture, SetupLocation, SetupOptions, SetupVersion

' Ici, il faut changer la valeur 2.5 par la version de votre installateur. Ceci représente également le nom
' du répertoire ou sera placé l'installateur.exe.
' Pour être plus clair, votre script sera dans un dossier partagé, et dans ce même dossier, un répertoire ayant
' comme nom la version de l'installateur doit avoir l'installateur .exe dans celui-ci.

SetupVersion = "2.5"

' Le commentaire SetupLocation qui suit permet de récupérer directement l'installateur via Internet. Pour activer cela, il suffit
' simplement supprimer l'apostrophe devant la ligne "SetupLocation" avec l'url Internet et en mettre une devant la
' ligne avec l'url partagé ou supprimer la ligne.

' SetupLocation = "https://github.com/fusioninventory/fusioninventory-agent/releases/download/" & SetupVersion
SetupLocation = "\\votre-serveur\le-dossier-partagé-ou-votre-script-est-mis\" & SetupVersion


' Vous pouvez laisser cela par défaut.
'    The setup architecture can be 'x86', 'x64' or 'Auto'
SetupArchitecture = "Auto"

' Remplacer les IP 77.77.77.77 par l'IP de votre GLPI et n'oubliez pas le netmask.
' Remplacer d777.org par un tag glpi ou le nom de votre domaine, le tag n'a pas vraiment trop d'influence.
SetupOptions = "/acceptlicense /server='http://77.77.77.77/glpi/plugins/fusioninventory/' /tag=d777.org /delaytime=60 /httpd-trust='127.0.0.1/32,77.77.77.77/26' /execmode=service /installtasks=full /runnow /S"

'    Cette ligne ne devrait pas être modifier du tout. Celui-ci va générer le nom de l'installateur afin de le trouver.
Setup = "fusioninventory-agent_windows-" & SetupArchitecture & "_" & SetupVersion & ".exe"

'    Forcer l'installation. 
'    Vous pouvez Laisser les valeurs par défaut.
Force = "No"

'    Vous pouvez Laisser les valeurs par défaut.
'    Enable or disable the information messages.
'    It's advisable to use Verbose = "Yes" with 'cscript //nologo ...'.
Verbose = "No"

' Cela étant fait, vous pouvez supprimer tout mes lignes de commentaires.

'
'
' NE PAS MODIFIER LE MODULE
'
'

Function AdvanceTime(nMinutes)
   Dim nMinimalMinutes, dtmTimeFuture
   ' As protection
   nMinimalMinutes = 5
   If nMinutes < nMinimalMinutes Then
      nMinutes = nMinimalMinutes
   End If
   ' Add nMinutes to the current time
   dtmTimeFuture = DateAdd ("n", nMinutes, Time)
   ' Format the result value
   '    The command AT accepts 'HH:MM' values only
   AdvanceTime = Hour(dtmTimeFuture) & ":" & Minute(dtmTimeFuture)
End Function

Function baseName (strng)
   Dim regEx, ret
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = True
   regEx.Pattern = ".*[/\\]([^/\\]+)$"
   baseName = regEx.Replace(strng,"$1")
End Function

Function GetSystemArchitecture()
   Dim strSystemArchitecture
   Err.Clear
   ' Get operative system architecture
   On Error Resume Next
   strSystemArchitecture = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%")
   If Err.Number = 0 Then
      ' Check the operative system architecture
      Select Case strSystemArchitecture
         Case "x86"
            ' The system architecture is 32-bit
            GetSystemArchitecture = "x86"
         Case "AMD64"
            ' The system architecture is 64-bit
            GetSystemArchitecture = "x64"
         Case Else
            ' The system architecture is not supported
            GetSystemArchitecture = "NotSupported"
      End Select
   Else
      ' It has been not possible to get the system architecture
      GetSystemArchitecture = "Unknown"
   End If
End Function

Function isHttp(strng)
   Dim regEx, matches
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = True
   regEx.Pattern = "^(http(s?)).*"
   If regEx.Execute(strng).count > 0 Then
      isHttp = True
   Else
      isHttp = False
   End If
   Exit Function
End Function

Function IsInstallationNeeded(strSetupVersion, strSetupArchitecture, strSystemArchitecture)
   Dim strCurrentSetupVersion
   ' Compare the current version, whether it exists, with strSetupVersion
   If strSystemArchitecture = "x86" Then
      ' The system architecture is 32-bit
      ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
      '    This subkey is now deprecated
      On error resume next
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\DisplayVersion")
      If Err.Number = 0 Then
      ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
         If strCurrentSetupVersion <> strSetupVersion Then
            ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
         ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' doesn't exist
         Err.Clear
         ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
         On error resume next
         strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\DisplayVersion")
         If Err.Number = 0 Then
         ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
            If strCurrentSetupVersion <> strSetupVersion Then
               ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
               IsInstallationNeeded = True
            End If
            Exit Function
         Else
            ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' doesn't exist
            Err.Clear
            ShowMessage("Installation needed: " & strSetupVersion)
            IsInstallationNeeded = True
         End If
      End If
   Else
      ' The system architecture is 64-bit
      ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
      '    This subkey is now deprecated
      On error resume next
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\DisplayVersion")
      If Err.Number = 0 Then
      ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
         If strCurrentSetupVersion <> strSetupVersion Then
            ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
         ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' doesn't exist
         Err.Clear
         ' Check if the subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
         On error resume next
         strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\DisplayVersion")
         If Err.Number = 0 Then
         ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
            If strCurrentSetupVersion <> strSetupVersion Then
               ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
               IsInstallationNeeded = True
            End If
            Exit Function
         Else
            ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' doesn't exist
            Err.Clear
            ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
            On error resume next
            strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\DisplayVersion")
            If Err.Number = 0 Then
            ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
               If strCurrentSetupVersion <> strSetupVersion Then
                  ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
                  IsInstallationNeeded = True
               End If
               Exit Function
            Else
               ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' doesn't exist
               Err.Clear
               ShowMessage("Installation needed: " & strSetupVersion)
               IsInstallationNeeded = True
            End If
         End If
      End If
   End If
End Function

Function IsSelectedForce()
   If LCase(Force) <> "no" Then
      ShowMessage("Installation forced: " & SetupVersion)
      IsSelectedForce = True
   Else
      IsSelectedForce = False
   End If
End Function

' http://www.ericphelps.com/scripting/samples/wget/index.html
Function SaveWebBinary(strSetupLocation, strSetup)
   Const adTypeBinary = 1
   Const adSaveCreateOverWrite = 2
   Const ForWriting = 2
   Dim web, varByteArray, strData, strBuffer, lngCounter, ado, strUrl
   strUrl = strSetupLocation & "/" & strSetup
   'On Error Resume Next
   'Download the file with any available object
   Err.Clear
   Set web = Nothing
   Set web = CreateObject("WinHttp.WinHttpRequest.5.1")
   If web Is Nothing Then Set web = CreateObject("WinHttp.WinHttpRequest")
   If web Is Nothing Then Set web = CreateObject("MSXML2.ServerXMLHTTP")
   If web Is Nothing Then Set web = CreateObject("Microsoft.XMLHTTP")
   web.Open "GET", strURL, False
   web.Send
   If Err.Number <> 0 Then
      SaveWebBinary = False
      Set web = Nothing
      Exit Function
   End If
   If web.Status <> "200" Then
      SaveWebBinary = False
      Set web = Nothing
      Exit Function
   End If
   varByteArray = web.ResponseBody
   Set web = Nothing
   'Now save the file with any available method
   On Error Resume Next
   Set ado = Nothing
   Set ado = CreateObject("ADODB.Stream")
   If ado Is Nothing Then
      Set fs = CreateObject("Scripting.FileSystemObject")
      Set ts = fs.OpenTextFile(baseName(strUrl), ForWriting, True)
      strData = ""
      strBuffer = ""
      For lngCounter = 0 to UBound(varByteArray)
         ts.Write Chr(255 And Ascb(Midb(varByteArray,lngCounter + 1, 1)))
      Next
      ts.Close
   Else
      ado.Type = adTypeBinary
      ado.Open
      ado.Write varByteArray
      ado.SaveToFile CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%") & "\" & strSetup, adSaveCreateOverWrite
      ado.Close
   End If
   SaveWebBinary = True
End Function

Function ShowMessage(strMessage)
   If LCase(Verbose) <> "no" Then
      WScript.Echo strMessage
   End If
End Function

'
'
' MAIN
'
'

Dim nMinutesToAdvance, strCmd, strSystemArchitecture, strTempDir, WshShell, objFSO
Set WshShell = WScript.CreateObject("WScript.shell")

nMinutesToAdvance = 5

' Get system architecture
strSystemArchitecture = GetSystemArchitecture()
If (strSystemArchitecture <> "x86") And (strSystemArchitecture <> "x64") Then
   ShowMessage("The system architecture is unknown or not supported.")
   ShowMessage("Deployment aborted!")
   WScript.Quit 1
Else
   ShowMessage("System architecture detected: " & strSystemArchitecture)
End If

' Check and auto detect SetupArchitecture
Select Case LCase(SetupArchitecture)
   Case "x86"
      ' The setup architecture is 32-bit
      SetupArchitecture = "x86"
      Setup = Replace(Setup, "x86", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture: " & SetupArchitecture)
   Case "x64"
      ' The setup architecture is 64-bit
      SetupArchitecture = "x64"
      Setup = Replace(Setup, "x64", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture: " & SetupArchitecture)
   Case "auto"
      ' Auto detection of SetupArchitecture
      SetupArchitecture = strSystemArchitecture
      Setup = Replace(Setup, "Auto", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture detected: " & SetupArchitecture)
   Case Else
      ' The setup architecture is not supported
      ShowMessage("The setup architecture '" & SetupArchitecture & "' is not supported.")
      WScript.Quit 2
End Select

' Check the relation between strSystemArchitecture and SetupArchitecture
If (strSystemArchitecture = "x86") And (SetupArchitecture = "x64") Then
   ' It isn't possible to execute a 64-bit setup on a 32-bit operative system
   ShowMessage("It isn't possible to execute a 64-bit setup on a 32-bit operative system.")
   ShowMessage("Deployment aborted!")
   WScript.Quit 3
End If

If IsSelectedForce() Or IsInstallationNeeded(SetupVersion, SetupArchitecture, strSystemArchitecture) Then
   If isHttp(SetupLocation) Then
      ShowMessage("Downloading: " & SetupLocation & "/" & Setup)
      If SaveWebBinary(SetupLocation, Setup) Then
         strCmd = WshShell.ExpandEnvironmentStrings("%ComSpec%")
         strTempDir = WshShell.ExpandEnvironmentStrings("%TEMP%")
         ShowMessage("Running: """ & strTempDir & "\" & Setup & """ " & SetupOptions)
         WshShell.Run """" & strTempDir & "\" & Setup & """ " & SetupOptions, 0, True
         ShowMessage("Scheduling: DEL /Q /F """ & strTempDir & "\" & Setup & """")
         WshShell.Run "AT.EXE " & AdvanceTime(nMinutesToAdvance) & " " & strCmd & " /C ""DEL /Q /F """"" & strTempDir & "\" & Setup & """""", 0, True
         ShowMessage("Deployment done!")
      Else
         ShowMessage("Error downloading '" & SetupLocation & "\" & Setup & "'!")
      End If
   Else
      Set objFSO = CreateObject("Scripting.FileSystemObject")
      strTempDir = WshShell.ExpandEnvironmentStrings("%TEMP%")
      ShowMessage("Copying: " & SetupLocation & "\" & Setup & " to " & strTempDir & "\" & Setup)
      objFSO.CopyFile SetupLocation & "\" & Setup, strTempDir & "\" & Setup, true
      ShowMessage("Running: """ & strTempDir & "\" & Setup & """ " & SetupOptions)
      WshShell.Run "CMD.EXE /C """ & strTempDir & "\" & Setup & """ " & SetupOptions, 0, True
      ShowMessage("Deployment done!")
   End If
Else
   ShowMessage("It isn't needed the installation of '" & Setup & "'.")
End If
