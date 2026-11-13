# Bank Details Remove Functionality - Solution

## Problem
The setting page "Bank Details" was showing a "remove" option (trash icon) but it was not functional - tapping it did nothing.

## Solution
Implemented individual bank account delete/remove functionality in `lib/screens/bank_details_view.dart`:

### Changes Made:

1. **Added delete icon** to each bank account row (right side, truncating IFSC text)
2. **Added onDelete callback** to `_BankAccountRow` widget
3. **Implemented `_deleteBankAccount` method** that:
   - Shows confirmation dialog: "Are you sure you want to remove 'Bank Name'?"
   - Removes the specific account from `SellerProfileStore.instance.bankAccounts`
   - Updates UI with `setState()`
   - Shows success/error snackbar messages
4. **Added `_getBankName` helper** to extract bank name from account map

### UI Change:
- Each bank account row now displays a delete (trash) icon `🗑️`
- Tapping the icon prompts for confirmation before removing
- After removal, the row disappears from the list

### Code Quality:
- `flutter analyze`: No issues found
- Follows existing code patterns in the codebase
- Uses `SellerProfileStore` for state management (consistent with existing code)

## Note
The existing `deleteBankDetails()` API only supports deleting ALL bank accounts for a user. This implementation removes individual accounts from the local store, which is the appropriate approach given the current codebase design.