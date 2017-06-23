Describe "RandomPassword Tests" {

     BeforeEach {
          $Error.Clear()
     }

     AfterEach {
          $Error.Clear()
     }

     It "Verifying password generation" {
          $Error.Clear()
          $randomPass = New-RandomPassword
          $Error.Count | Should Be 0
          $randomPass | Should Not Be $null
     }

     It "Verifying a password length of 15 characters" {
          $Error.Clear()
          $randomPass = New-RandomPassword
          $Error.Count | Should Be 0
          $randomPass | Should Not Be $null
          $randomPass.Length | Should Be 15
     }
}

Describe "Encryption/Decryption Test" {
     BeforeEach {
          $Error.Clear()
     }

     AfterEach {\
          $Error.Clear()
     }

     It "Encrypts the string" {
          $Error.Clear()
          $TestStringValue = 'TestString1234'

          $eString = Protect-String -String $TestStringValue
          $Error.Count | Should Be 0
          $eString | Should Not Be $null

          $dcString = Unprotect-String -EncryptedString $eString
          $Error.Count | Should Be 0
          $dcString | Should Not Be $null
          $dcString | Should Be $TestStringValue
     }
}