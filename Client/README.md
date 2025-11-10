# SideWinder Deploy Client

## Modal Dialog Refactor

The custom `ModalManager` component used to provide a lightweight backdrop + fade implementation. This has been replaced with HaxeUI's built-in `Dialog` (`haxe.ui.containers.dialogs.Dialog`) for simpler lifecycle handling, built-in centering, and consistent overlay behavior.

### Changes

- Removed file `Source/components/ModalManager.hx`.
- Replaced modal usage in `ReleasesTab.hx` and `ProjectVariablesTab.hx` with `Dialog` instances.
- Removed legacy modal CSS definitions in `Main.hx` (backdrop and container). Existing overlay styling is applied via the `releaseFormOverlay` and `variableFormOverlay` style classes directly to the dialog's container.

### Creating a Dialog

```haxe
var dlg = new Dialog();
dlg.title = "Create Release";
dlg.closable = true;        // shows titlebar close button
dlg.buttons = null;         // form supplies its own buttons
dlg.destroyOnClose = true;  // dispose automatically on close
dlg.dialogContainer.addClass("releaseFormOverlay");
dlg.addComponent(formContent); // add your form VBox
dlg.onDialogClosed = function(e) {
	// cleanup logic
};
dlg.showDialog(true);       // 'true' => modal
```

To close programmatically:

```haxe
dlg.hideDialog("cancel"); // or "close" / any button id string
```

### Notes

- `DialogButton` abstract wasn't imported; simple string identifiers are passed to `hideDialog` for close actions.
- Overlay sizing and centering are handled internally by HaxeUI; no manual resize polling needed anymore.
- If additional global dialog styling is needed, target HaxeUI dialog style names: `dialog-container`, `dialog-title`, `dialog-content`, etc.

### Follow Ups

- Consolidate duplicate form styling into a shared CSS class if more dialogs are added.
- Consider replacing inline wizard insertion (`DeploymentWizard`) with a dialog for consistency.

