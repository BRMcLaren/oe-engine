    "adminUsername": "[parameters('adminUsername')]",
{{if .IsLinux}}{{if .LinuxProfile.HasSecrets}}
    "linuxProfileSecrets" :
      [
          {{range  $vIndex, $vault := .LinuxProfile.Secrets}}
            {{if $vIndex}} , {{end}}
              {
                "sourceVault":{
                  "id":"[parameters('linuxKeyVaultID{{$vIndex}}')]"
                },
                "vaultCertificates":[
                {{range $cIndex, $cert := $vault.VaultCertificates}}
                  {{if $cIndex}} , {{end}}
                  {
                    "certificateUrl" :"[parameters('linuxKeyVaultID{{$vIndex}}CertificateURL{{$cIndex}}')]"
                  }
                {{end}}
                ]
              }
        {{end}}
      ],
{{end}}{{end}}
    "publicIPAddressName": "[concat(parameters('vmName'), '-ip')]",
    "nsgName": "[concat(parameters('vmName'), '-nsg')]",
    "nsgID": "[resourceId('Microsoft.Network/networkSecurityGroups',variables('nsgName'))]",
    "vnetSubnetID": "[resourceId(parameters('vnetResourceGroupName'), 'Microsoft.Network/virtualNetworks/subnets/', parameters('vnetName'), parameters('subnetName'))]",
    {{GetOSImageReferences}},
    "linuxConfiguration": {
      "disablePasswordAuthentication": "true",
      "ssh": {
        "publicKeys": [
          {
            "keyData": "[parameters('adminPasswordOrKey')]",
            "path": "[concat('/home/', parameters('adminUsername'), '/.ssh/authorized_keys')]"
          }
        ]
      }
    },
    "singleQuote": "'",
    "windowsConfiguration": {
      "provisionVmAgent": "true"
    },
    "linuxSecurityRules": [
      {
        "properties": {
          "priority": 200,
          "access": "Allow",
          "direction": "Inbound",
          "destinationPortRange": "22",
          "sourcePortRange": "*",
          "destinationAddressPrefix": "*",
          "protocol": "Tcp",
          "description": "Allow SSH",
          "sourceAddressPrefix": "*"
        },
        "name": "ssh"
      }
    ],
    "windowsSecurityRules": [
      {
        "properties": {
          "priority": 200,
          "access": "Allow",
          "direction": "Inbound",
          "destinationPortRange": "3389",
          "sourcePortRange": "*",
          "destinationAddressPrefix": "*",
          "protocol": "Tcp",
          "description": "Allow RDP",
          "sourceAddressPrefix": "*"
        },
        "name": "rdp"
      },
      {
        "properties": {
          "priority": 210,
          "access": "Allow",
          "direction": "Inbound",
          "destinationPortRange": "22",
          "sourcePortRange": "*",
          "destinationAddressPrefix": "*",
          "protocol": "Tcp",
          "description": "Allow SSH",
          "sourceAddressPrefix": "*"
        },
        "name": "ssh"
      }
    ],
    "securityRules": "[if(equals(parameters('osImageName'), 'WindowsServer_2016'), variables('windowsSecurityRules'), variables('linuxSecurityRules'))]",
    "diagnosticsStorageAction": "[if(equals(parameters('bootDiagnostics'), 'disable'), 'nop', parameters('diagnosticsStorageAccountNewOrExisting'))]",
    "linuxExtCommand": "[if(equals(parameters('oeSDKIncluded'), 'yes'), '/bin/bash -c \"secs=600; SECONDS=0; while (( SECONDS < secs )); do if [ -e /opt/azure/acc/completed ]; then if [ $(cat /opt/azure/acc/completed) == ok ]; then /opt/azure/acc/validate.sh; exit $? ; else echo provision failed; exit 1; fi; fi; sleep 20; done; echo validation timeout; exit 1; \"', '/bin/bash -c \"exit 0\"')]",

    "winScriptSuffix": " $inputFile = '\\AzureData\\CustomData.bin' ; $outputFile = '\\AzureData\\oeWindowsProvision.ps1' ; $inputStream = New-Object System.IO.FileStream $inputFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read) ; $sr = New-Object System.IO.StreamReader(New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)) ; $sr.ReadToEnd() | Out-File($outputFile) ; &$outputFile ; ",
    "winScriptArguments": "[concat('$arguments = ', variables('singleQuote'),' ',variables('singleQuote'), ' ; ')]",
    "windowsExtScript": "[concat('powershell.exe -ExecutionPolicy Unrestricted -command \"', variables('winScriptSuffix'), '\" > \\AzureData\\provisionScript.log 2>&1; exit $LASTEXITCODE')]"
