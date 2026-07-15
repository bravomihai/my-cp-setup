import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INSTALL = (ROOT / "scripts" / "install.bat").read_text(encoding="utf-8")
UNINSTALL = (ROOT / "scripts" / "uninstall.bat").read_text(encoding="utf-8")


def label(source: str, name: str) -> str:
    match = re.search(
        rf"(?ms)^:{re.escape(name)}\s*$\n(.*?)(?=^:[A-Za-z0-9_]+\s*$|\Z)",
        source,
    )
    if not match:
        raise AssertionError(f"missing label: {name}")
    return match.group(1)


def embedded(source: str, name: str) -> str:
    lines = source.splitlines()
    first = lines.index(f"::{name}_BEGIN__")
    last = lines.index(f"::{name}_END__")
    payload = lines[first + 1 : last]
    if not all(line.startswith("::") for line in payload):
        raise AssertionError(f"malformed embedded block: {name}")
    return "\n".join(line[2:] for line in payload)


class StateLifecycleContractTests(unittest.TestCase):
    def test_fresh_snapshot_is_immutable_and_retry_only_adds_mutation_state(
        self,
    ) -> None:
        initialize = label(INSTALL, "initialize_state")
        self.assertIn("-notcontains 'Snapshot.Complete'", initialize)
        self.assertEqual(initialize.count("SetValue^('Snapshot.Complete'"), 1)
        self.assertIn("Snapshot-StringValue", initialize)
        artifact_capture = initialize.index(
            "call :capture_target_profile_artifacts snapshot"
        )
        state_writer = initialize.index('set "STATE_INIT_PS=')
        artifact_before = initialize.index("SetValue^('Artifacts.Before.Paths'")
        artifact_created = initialize.index("SetValue^('Artifacts.Created.Paths'")
        snapshot_complete = initialize.index("SetValue^('Snapshot.Complete'")
        self.assertLess(artifact_capture, state_writer)
        self.assertLess(artifact_before, artifact_created)
        self.assertLess(artifact_created, snapshot_complete)
        self.assertIn("RegistryValueKind]::MultiString", initialize)

        mutation = label(INSTALL, "prepare_config_mutation")
        self.assertIn("Config.MutationStarted", mutation)
        self.assertIn("if($null -eq $raw)", mutation)
        self.assertIn("elseif", mutation)

        bootstrap = label(INSTALL, "prepare_nvim_bootstrap")
        self.assertIn("if ^($names -contains 'Nvim.BootstrapStarted'^)", bootstrap)
        self.assertIn("Invalid Neovim bootstrap state", bootstrap)

    def test_snapshot_only_uninstall_clears_metadata_without_touching_user_values(
        self,
    ) -> None:
        cleanup = label(UNINSTALL, "remove_setup_configuration")
        self.assertIn("$validateSnapshot", cleanup)
        self.assertIn(
            "if ^(-not $written.Exists -and -not $writtenKind.Exists^)", cleanup
        )
        self.assertIn("$pathMutation", cleanup)
        self.assertIn("if ^(-not $pathMutation^)", cleanup)
        self.assertIn("$autoMutation", cleanup)
        self.assertIn("if ^(-not $autoMutation^)", cleanup)
        self.assertIn("$consoleMutation", cleanup)
        self.assertIn("if ^(-not $consoleMutation^)", cleanup)

        # A half-written mutation is not silently accepted as snapshot-only.
        for message in (
            "Incomplete environment ownership metadata",
            "Incomplete Path ownership metadata",
            "Incomplete AutoRun ownership metadata",
            "Incomplete console ownership metadata",
        ):
            self.assertIn(message, cleanup)
        self.assertIn("$validateSnapshot 'Console.VirtualTerminal' 4 @^(4^)", cleanup)

    def test_snapshot_only_neovim_state_cannot_delete_later_user_data(self) -> None:
        cleanup = label(UNINSTALL, "remove_nvim_generated_data")
        self.assertIn("Nvim.BootstrapStarted", cleanup)
        check = cleanup.index("Nvim.BootstrapStarted")
        removal = cleanup.index("Remove-SafeTree $target")
        self.assertLess(check, removal)
        self.assertIn("Invalid Neovim bootstrap state", cleanup)
        self.assertRegex(
            cleanup,
            r"(?s)BootstrapStarted.*?\$bootstrapStarted.*?if \^\(\$bootstrapStarted",
        )

    def test_crash_window_without_install_root_is_a_strict_snapshot_state(self) -> None:
        context = label(UNINSTALL, "initialize_target_context_safe")
        for token in (
            "$status='SNAPSHOT'",
            "JdtlsWorkspace.Path",
            "Artifacts.Before.Paths",
            "Artifacts.Created.Paths",
            "RegistryValueKind]::MultiString",
            "@^($state.GetValue^('Artifacts.Created.Paths',$null,$option^)^).Count -ne 0",
            "Incomplete snapshot artifact metadata",
            "Invalid snapshot artifact metadata",
        ):
            self.assertIn(token, context)

        root_check = label(UNINSTALL, "check_state_root")
        for token in (
            "CP_SETUP_STATE_CONTEXT -ne 'SNAPSHOT'",
            "JdtlsWorkspace.Path",
            "Artifacts.Before.Paths",
            "Artifacts.Created.Paths",
            "RegistryValueKind]::MultiString",
            "GetValue('Artifacts.Created.Paths',$null,$option)).Count -ne 0",
        ):
            self.assertIn(token, root_check)

        artifacts = label(UNINSTALL, "remove_created_artifacts")
        snapshot_gate = artifacts.index(
            'if /I not "%CP_SETUP_STATE_CONTEXT%"=="SNAPSHOT"'
        )
        recovery = artifacts.index('call :capture_native_msys2_artifacts "recover"')
        self.assertLess(snapshot_gate, recovery)

    def test_artifact_inventory_has_a_producer_and_strict_consumer(self) -> None:
        producer = embedded(UNINSTALL, "__CP_NATIVE_ARTIFACTS")
        for token in (
            "@('before','after','recover')",
            "$phase-in@('before','recover')",
            "}else{",
            "Artifacts.Before.Paths",
            "Artifacts.Created.Paths",
            "RegistryValueKind]::MultiString",
            "qt-installer-framework",
            "manifest.json",
            "Assert-NoReparsePath",
            "SetEquals",
        ):
            self.assertIn(token, producer)
        self.assertIn(
            "Native uninstaller created a non-allowlisted cache entry", producer
        )

        consumer = label(UNINSTALL, "remove_created_artifacts")
        for token in (
            "Artifacts.Before.Paths",
            "Artifacts.Created.Paths",
            "$before -icontains $full",
            "Assert-NoReparsePath",
            "Artifact cleanup verification failed",
        ):
            self.assertIn(token, consumer)
        self.assertLess(
            consumer.index("Artifact cleanup verification failed"),
            consumer.index("call :commit_state_metadata"),
        )

    def test_pending_transactions_are_atomic_hashed_and_retry_safe(self) -> None:
        registry = label(UNINSTALL, "recover_pending_registry")
        for token in (
            "Pending.Registry.Intent",
            "Hash-Bytes",
            "prepared",
            "committed",
            "$mutationCount -ne 6",
            "Incomplete pending environment mutation set",
            "[array]::Reverse",
            "run_medium_worker",
        ):
            self.assertIn(token, registry)

        mason = (
            label(UNINSTALL, "recover_pending_mason")
            + embedded(UNINSTALL, "__CP_PENDING_MASON_WORKER")
            + embedded(UNINSTALL, "__CP_PENDING_MASON_COMMIT")
        )
        for token in (
            "Pending.Mason.Intent",
            "BeforePackages",
            "OwnedPackages",
            "Mason.Inventory.Frozen",
            "run_medium_worker",
        ):
            self.assertIn(token, mason)

        components = label(UNINSTALL, "recover_pending_components")
        for token in (
            "Pending.Winget.Intent",
            "Pending.Pacman.Intent",
            "BaselinePresent",
            "BaselineAbsentPackages",
            "v2",
            "Hash-Bytes",
        ):
            self.assertIn(token, components)


if __name__ == "__main__":
    unittest.main()
