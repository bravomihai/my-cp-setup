import subprocess
import tempfile
import unittest
from pathlib import Path

from tests.test_uninstall_contract import (
    embedded_block,
    label_block,
    rendered_powershell,
)


POWERSHELL = r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"


class UninstallRuntimeTests(unittest.TestCase):
    def _run_powershell(
        self, source: str, timeout: int = 45
    ) -> subprocess.CompletedProcess:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".ps1", delete=False
        ) as stream:
            stream.write(source)
            path = Path(stream.name)
        try:
            return subprocess.run(
                [
                    POWERSHELL,
                    "-NoLogo",
                    "-NoProfile",
                    "-NonInteractive",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(path),
                ],
                capture_output=True,
                text=True,
                timeout=timeout,
                check=False,
            )
        finally:
            path.unlink(missing_ok=True)

    def test_real_config_worker_preserves_user_path_autorun_and_vtl_changes(
        self,
    ) -> None:
        source = rendered_powershell(
            label_block("remove_setup_configuration", "remove_external_components"),
            "CONFIG_CLEANUP_PS",
        )
        source = source.replace(
            "[Microsoft.Win32.Registry]::Users",
            "[Microsoft.Win32.Registry]::CurrentUser",
        ).replace(
            "[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey",
            "[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey",
        )
        source = source.rsplit("exit 0", 1)[0]

        harness = r"""
$ErrorActionPreference='Stop'
$root='Software\my-cp-setup-tests\'+[guid]::NewGuid().ToString('N')
$target=$root+'\Target';$stateRelative=$root+'\State'
$env:CP_SETUP_TARGET_SID=$target
$env:CP_SETUP_TARGET_STATE_RELATIVE=$stateRelative
$users=[Microsoft.Win32.Registry]::CurrentUser
try {
  $envKey=$users.CreateSubKey($target+'\Environment')
  $autoKey=$users.CreateSubKey($target+'\Software\Microsoft\Command Processor')
  $consoleKey=$users.CreateSubKey($target+'\Console')
  $state=$users.CreateSubKey($stateRelative)
  try {
    $owned1='C:\CP\scripts';$owned2='C:\Tools\g++\bin'
    $pathBefore='C:\Before';$pathWritten=$pathBefore+';'+$owned1+';'+$owned2
    $pathCurrent=$pathBefore+';'+$owned1+';D:\Custom;'+$owned2
    $envKey.SetValue('Path',$pathCurrent,[Microsoft.Win32.RegistryValueKind]::ExpandString)
    $state.SetValue('Path.HadValue',1,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('Path.Before',$pathBefore,[Microsoft.Win32.RegistryValueKind]::String)
    $state.SetValue('Path.Before.Kind',1,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('Path.Written',$pathWritten,[Microsoft.Win32.RegistryValueKind]::String)
    $state.SetValue('Path.Written.Kind',2,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('Path.Entries',[string[]]@($owned1,$owned2),[Microsoft.Win32.RegistryValueKind]::MultiString)

    $owned='doskey /macrofile="C:\CP\scripts\cp_macros"'
    $autoBefore='user-before';$autoWritten=$autoBefore+' & '+$owned
    $autoCurrent=$autoWritten+' & user-after'
    $autoKey.SetValue('AutoRun',$autoCurrent,[Microsoft.Win32.RegistryValueKind]::String)
    $state.SetValue('AutoRun.HadValue',1,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('AutoRun.Before',$autoBefore,[Microsoft.Win32.RegistryValueKind]::String)
    $state.SetValue('AutoRun.Before.Kind',1,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('AutoRun.Entry',$owned,[Microsoft.Win32.RegistryValueKind]::String)
    $state.SetValue('AutoRun.Written',$autoWritten,[Microsoft.Win32.RegistryValueKind]::String)
    $state.SetValue('AutoRun.Written.Kind',1,[Microsoft.Win32.RegistryValueKind]::DWord)

    $consoleKey.SetValue('VirtualTerminalLevel',2,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('Console.VirtualTerminal.HadValue',0,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('Console.VirtualTerminal.Written',1,[Microsoft.Win32.RegistryValueKind]::DWord)
    $state.SetValue('Console.VirtualTerminal.Written.Kind',4,[Microsoft.Win32.RegistryValueKind]::DWord)
  } finally { $envKey.Dispose();$autoKey.Dispose();$consoleKey.Dispose();$state.Dispose() }

__WORKER__

  $envKey=$users.OpenSubKey($target+'\Environment',$false)
  $autoKey=$users.OpenSubKey($target+'\Software\Microsoft\Command Processor',$false)
  $consoleKey=$users.OpenSubKey($target+'\Console',$false)
  try {
    if([string]$envKey.GetValue('Path') -cne 'C:\Before;D:\Custom'){throw 'Path user change was not preserved.'}
    if($envKey.GetValueKind('Path') -ne [Microsoft.Win32.RegistryValueKind]::ExpandString){throw 'Path kind changed.'}
    if([string]$autoKey.GetValue('AutoRun') -cne 'user-before & user-after'){throw 'AutoRun user change was not preserved.'}
    if($autoKey.GetValueKind('AutoRun') -ne [Microsoft.Win32.RegistryValueKind]::String){throw 'AutoRun kind changed.'}
    if([int]$consoleKey.GetValue('VirtualTerminalLevel') -ne 2){throw 'VTL user change was not preserved.'}
    if($consoleKey.GetValueKind('VirtualTerminalLevel') -ne [Microsoft.Win32.RegistryValueKind]::DWord){throw 'VTL kind changed.'}
  } finally { $envKey.Dispose();$autoKey.Dispose();$consoleKey.Dispose() }
} finally {
  try {$users.DeleteSubKeyTree($root,$false)} catch {}
}
""".replace("__WORKER__", source)

        result = self._run_powershell(harness)
        self.assertEqual(0, result.returncode, result.stderr or result.stdout)

    def test_process_tree_helper_kills_root_child_and_grandchild(self) -> None:
        native = embedded_block("__CP_PROCESS_TREE_NATIVE")
        helper = embedded_block("__CP_PROCESS_TREE_PS")
        harness = r"""
$ErrorActionPreference='Stop'
$rootDir=Join-Path ([IO.Path]::GetTempPath()) ('cp-uninstall-tree-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($rootDir)|Out-Null
$nativePath=Join-Path $rootDir 'tree.cs';$env:PROCESS_TREE_NATIVE_CS=$nativePath
[IO.File]::WriteAllText($nativePath,@'
__NATIVE__
'@,[Text.UTF8Encoding]::new($false))
__HELPER__
$childCode='$grand=Start-Process -FilePath $env:POWERSHELL_EXE -ArgumentList @(''-NoProfile'',''-Command'',''Start-Sleep -Seconds 60'') -PassThru -WindowStyle Hidden;[IO.File]::WriteAllText($env:GRAND_PID,[string]$grand.Id);Start-Sleep -Seconds 60'
$childEncoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childCode))
$rootCode='$child=Start-Process -FilePath $env:POWERSHELL_EXE -ArgumentList @(''-NoProfile'',''-EncodedCommand'',$env:CHILD_ENCODED) -PassThru -WindowStyle Hidden;[IO.File]::WriteAllText($env:CHILD_PID,[string]$child.Id);Start-Sleep -Seconds 60'
$rootEncoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($rootCode))
$env:POWERSHELL_EXE='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$env:CHILD_ENCODED=$childEncoded;$env:CHILD_PID=Join-Path $rootDir 'child.pid';$env:GRAND_PID=Join-Path $rootDir 'grand.pid'
$root=Start-Process -FilePath $env:POWERSHELL_EXE -ArgumentList @('-NoProfile','-EncodedCommand',$rootEncoded) -PassThru -WindowStyle Hidden
try {
  $deadline=[DateTime]::UtcNow.AddSeconds(10)
  while(((-not(Test-Path $env:CHILD_PID))-or(-not(Test-Path $env:GRAND_PID)))-and[DateTime]::UtcNow-lt$deadline){Start-Sleep -Milliseconds 100}
  if(-not(Test-Path $env:CHILD_PID)-or-not(Test-Path $env:GRAND_PID)){throw'Process tree did not start.'}
  $childPid=[int][IO.File]::ReadAllText($env:CHILD_PID);$grandPid=[int][IO.File]::ReadAllText($env:GRAND_PID)
  Stop-VerifiedProcessTree $root $null
  foreach($pidValue in @($root.Id,$childPid,$grandPid)){try{$p=[Diagnostics.Process]::GetProcessById($pidValue);try{if(-not$p.HasExited){throw('Survivor: '+$pidValue)}}finally{$p.Dispose()}}catch [ArgumentException]{}}
} finally {
  try{if(-not$root.HasExited){$root.Kill()}}catch{};$root.Dispose()
  Remove-Item -LiteralPath $rootDir -Recurse -Force -ErrorAction SilentlyContinue
}
""".replace("__NATIVE__", native).replace("__HELPER__", helper)
        result = self._run_powershell(harness, timeout=60)
        self.assertEqual(0, result.returncode, result.stderr or result.stdout)

    def test_source_lease_hashes_and_locks_file_and_ancestors(self) -> None:
        native = embedded_block("__CP_SOURCE_LOCK_NATIVE")
        with tempfile.TemporaryDirectory(prefix="cp-uninstall-lock-") as temporary:
            root = str(Path(temporary).resolve()).replace("'", "''")
            harness = r"""
$ErrorActionPreference='Stop'
Add-Type -TypeDefinition @'
__NATIVE__
'@ -Language CSharp
$root='__ROOT__'
$source=Join-Path $root 'uninstall.bat';[IO.File]::WriteAllText($source,'locked-source',[Text.Encoding]::UTF8)
$lease=[CpSetup.Native.SourceLease]::Acquire($source)
try {
  $expected=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
  if($lease.Hash-cne$expected){throw'Source hash mismatch.'}
  $code='$writeBlocked=$false;$moveBlocked=$false;try{[IO.File]::WriteAllText($env:LOCK_SOURCE,''changed'')}catch{$writeBlocked=$true};try{[IO.Directory]::Move($env:LOCK_ROOT,$env:LOCK_ROOT+''.moved'')}catch{$moveBlocked=$true};if($writeBlocked-and$moveBlocked){exit 0};exit 1'
  $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
  $env:LOCK_SOURCE=$source;$env:LOCK_ROOT=$root
  $probe=Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList @('-NoProfile','-EncodedCommand',$encoded) -PassThru -WindowStyle Hidden
  if(-not$probe.WaitForExit(10000)){try{$probe.Kill()}catch{};throw'Lock probe timed out.'}
  if(-not$probe.WaitForExit(1000)-or$probe.ExitCode-ne0){throw'Source or ancestor lock was bypassed.'}
  $probe.Dispose()
} finally {$lease.Dispose()}
""".replace("__NATIVE__", native).replace("__ROOT__", root)
            result = self._run_powershell(harness, timeout=45)
            self.assertEqual(0, result.returncode, result.stderr or result.stdout)


if __name__ == "__main__":
    unittest.main()
