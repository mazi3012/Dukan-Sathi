# GST Billing Formatter - Test Cases & Examples

## Example Scenario 1: Bill with 10% Discount (Registered Seller, Intra-State)

### Inputs
```dart
Final DraftApproval approval = DraftApproval(
  approvalId: 'draft_001',
  proposedTotal: 531.00,  // Grand total with taxes
  proposedTaxBreakdown: TaxBreakdown(
    subtotal: 450.00,     // After discount
    cgstAmount: 40.50,
    sgstAmount: 40.50,
    igstAmount: 0,
    gstMode: 'REGISTERED',
    applicableState: 'MH',
    totalAmount: 531.00,
    breakdown: [...]
  )
);

String customerName = 'Jitu';
List<String> itemDescriptions = ['2x Organic Honey 500g @ ₹250'];
String? paymentStatus = 'UNPAID';
double? amountPaid = 0.0;
double? dueAmount = 531.00;
String? discountType = 'PERCENT';
double? discountValue = 10.0;
double? discountAmount = 50.0;
double? subtotalBeforeDiscount = 500.0;
double? subtotalAfterDiscount = 450.0;
```

### Output (NEW FORMAT)
```
📦 Items:
  • 2x Organic Honey 500g @ ₹250

💰 Billing Summary:
────────────────────
Items Total:   ₹500.00
Discount:      -₹50.00 (10.0%)
Taxable Value: ₹450.00

CGST (9%):     ₹40.50
SGST (9%):     ₹40.50

TOTAL:         ₹531.00

Paid:          ₹0.00
DUE:           ₹531.00
────────────────────

📍 State: MH — Intra-State
💳 Status: UNPAID
🆔 `draft_001`
```

### Calculation Verification
```
Step 1: Items Total (Gross)     = ₹500.00
Step 2: Discount (10%)          = ₹500.00 × 10% = -₹50.00
Step 3: Taxable Value           = ₹500.00 - ₹50.00 = ₹450.00
Step 4: CGST (9%)               = ₹450.00 × 9% = ₹40.50
Step 5: SGST (9%)               = ₹450.00 × 9% = ₹40.50
Step 6: Grand Total             = ₹450.00 + ₹40.50 + ₹40.50 = ₹531.00
Step 7: Amount Paid             = ₹0.00
Step 8: Balance Due              = ₹531.00 - ₹0.00 = ₹531.00 ✓
```

---

## Example Scenario 2: Partial Payment with ₹250 Paid

### Inputs
```dart
// Same as above, but:
String? paymentStatus = 'PARTIAL';
double? amountPaid = 250.0;
double? dueAmount = 281.00;
```

### Output (NEW FORMAT)
```
📦 Items:
  • 2x Organic Honey 500g @ ₹250

💰 Billing Summary:
────────────────────
Items Total:   ₹500.00
Discount:      -₹50.00 (10.0%)
Taxable Value: ₹450.00

CGST (9%):     ₹40.50
SGST (9%):     ₹40.50

TOTAL:         ₹531.00

Paid:          ₹250.00
DUE:           ₹281.00
────────────────────

📍 State: MH — Intra-State
💳 Status: PARTIAL
🆔 `draft_001`
```

### Calculation Verification
```
Step 1-6: Same as above = ₹531.00 total
Step 7: Amount Paid      = ₹250.00
Step 8: Balance Due      = ₹531.00 - ₹250.00 = ₹281.00 ✓
```

---

## Example Scenario 3: Inter-State Transaction (IGST 18%)

### Inputs
```dart
Final DraftApproval approval = DraftApproval(
  approvalId: 'draft_002',
  proposedTotal: 590.00,  // With IGST
  proposedTaxBreakdown: TaxBreakdown(
    subtotal: 500.00,
    cgstAmount: 0,
    sgstAmount: 0,
    igstAmount: 90.00,    // 18% IGST
    gstMode: 'REGISTERED',
    applicableState: 'MH',  // But customer is from different state
    totalAmount: 590.00,
    breakdown: [...]
  )
);

String customerName = 'Walk-in Customer';
List<String> itemDescriptions = ['1x Mobile ₹500'];
String? discountType = null;
double? discountAmount = 0.0;
double? subtotalBeforeDiscount = 500.0;
double? subtotalAfterDiscount = 500.0;
String? paymentStatus = 'UNPAID';
```

### Output (NEW FORMAT)
```
📦 Items:
  • 1x Mobile ₹500

💰 Billing Summary:
────────────────────
Items Total:   ₹500.00
Taxable Value: ₹500.00

IGST (18%):    ₹90.00

TOTAL:         ₹590.00

Paid:          ₹0.00
DUE:           ₹590.00
────────────────────

📍 State: Inter-State (IGST)
💳 Status: UNPAID
🆔 `draft_002`
```

### Notes
- No discount line shown (discountAmount = 0)
- IGST shown instead of CGST+SGST
- State label shows "Inter-State (IGST)"

---

## Example Scenario 4: Fixed Amount Discount (₹100 off)

### Inputs
```dart
String? discountType = 'AMOUNT';
double? discountValue = 100.0;  // Fixed ₹100
double? discountAmount = 100.0;
double? subtotalBeforeDiscount = 500.0;
double? subtotalAfterDiscount = 400.0;

// Tax calculated on ₹400 (after discount)
// CGST = 36.00, SGST = 36.00
proposedTotal = 472.00;
```

### Output (NEW FORMAT)
```
📦 Items:
  • Sample items...

💰 Billing Summary:
────────────────────
Items Total:   ₹500.00
Discount:      -₹100.00
Taxable Value: ₹400.00

CGST (9%):     ₹36.00
SGST (9%):     ₹36.00

TOTAL:         ₹472.00

DUE:           ₹472.00
────────────────────
```

### Notes
- Fixed amount discount shows "-₹100.00" (no percentage)
- If percentage is also known, it would show "Discount: -₹100.00 (20%)"

---

## Example Scenario 5: Unregistered Seller (No GST)

### Inputs
```dart
proposedTaxBreakdown: TaxBreakdown(
  subtotal: 500.00,
  cgstAmount: 0,
  sgstAmount: 0,
  igstAmount: 0,
  gstMode: 'UNREGISTERED',
  ...
);
proposedTotal = 500.00;  // No taxes added
```

### Output (NEW FORMAT)
```
📦 Items:
  • Sample items...

💰 Billing Summary:
────────────────────
Items Total:   ₹500.00
Taxable Value: ₹500.00

GST:           None (Unregistered)

TOTAL:         ₹500.00

DUE:           ₹500.00
────────────────────
```

---

## Comparing OLD vs NEW Format

### OLD FORMAT (Problematic)
```
🧾 *INVOICE FOR APPROVAL*

👤 Customer: Jitu
📦 Items:
  • 2x Organic Honey 500g @ ₹250

💰 *Billing Summary*
━━━━━━━━━━━━━━━━━
Subtotal: ₹450.00        ← CONFUSING: Shows after-discount value
Before Discount: ₹500.00
Discount: 10% (₹50.00)   ← REDUNDANT: Both sign and amount
Payment: UNPAID          ← SANDWICH ERROR: Mixed in middle
Paid: ₹0.00              ← SANDWICH ERROR: Before taxes shown
Due: ₹50.00              ← SANDWICH ERROR: Before TOTAL shown
CGST (9%): ₹40.50
SGST (9%): ₹40.50
━━━━━━━━━━━━━━━━━
*TOTAL: ₹531.00*         ← NOW visible, but after all the confusion

📍 State: MH — Intra-State
⏳ Status: Awaiting Approval
🆔 `approval-id`
```

**Problems:**
1. ❌ "Subtotal" label is confusing (shows after-discount value)
2. ❌ "Before Discount" and "Discount" aren't aligned
3. ❌ Discount format shows "10% (₹50.00)" - both unnecessary details
4. ❌ Payment info mixed with tax calculations ("SANDWICH ERROR")
5. ❌ Revenue shown before TOTAL is displayed
6. ❌ "Due" not in final position
7. ❌ User can't easily follow the math flow

### NEW FORMAT (GST-Compliant)
```
📦 Items:
  • 2x Organic Honey 500g @ ₹250

💰 Billing Summary:
────────────────────
Items Total:   ₹500.00    ← CLEAR: Gross before discount
Discount:      -₹50.00 (10%) ← CLEAR: Both amount and %
Taxable Value: ₹450.00    ← CLEAR: Price taxes are applied to
                          ← Blank line for clarity
CGST (9%):     ₹40.50     ← Taxes clearly separated
SGST (9%):     ₹40.50     ← Taxes clearly separated
                          ← Blank line for clarity
TOTAL:         ₹531.00    ← Grand total prominent
                          ← Blank line for clarity
Paid:          ₹0.00      ← Payment info AFTER total
DUE:           ₹531.00    ← Due is FINAL line (no sandwich)
────────────────────

📍 State: MH — Intra-State
💳 Status: UNPAID
🆔 `approval-id`
```

**Benefits:**
1. ✅ Clear hierarchy: Items → Discount → Taxable Value → Taxes → Total → Payment
2. ✅ "Items Total" is unambiguous (gross)
3. ✅ "Taxable Value" shows what taxes apply to
4. ✅ Discount shows percentage for transparency
5. ✅ TOTAL clearly separated from taxes
6. ✅ Payment info isolated from calculations
7. ✅ Due amount is final line (no mixing)
8. ✅ User can follow the calculation step-by-step
9. ✅ Aligns with Indian GST invoice standards
10. ✅ Easier to audit for correctness

---

## Testing This Implementation

### Quick Test in Telegram
Send: `Make a bill for Jitu, 2 Organic Honey 500g @ 250 each, 10% discount`

Expected response should show:
- ✅ Items Total: ₹500
- ✅ Discount: -₹50 (10%)
- ✅ Taxable Value: ₹450
- ✅ CGST/SGST calculated correctly
- ✅ TOTAL shown clearly
- ✅ DUE as final line
- ✅ No "sandwich" error

### Validation Points
1. All amounts have exactly .00 decimal places
2. Discount line only appears if discount > 0
3. Paid line only appears if amount_paid > 0
4. DUE = TOTAL - Paid (always accurate)
5. Tax calculations use Taxable Value (after discount)
