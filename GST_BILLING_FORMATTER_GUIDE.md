# GST Billing Formatter - Complete Reference Guide

## Overview
Updated the invoice formatting logic in `/lib/services/approval_formatter.dart` to follow proper Indian GST formatting standards and fix the "sandwich error."

## Key Changes

### Problem Fixed: The "Sandwich Error"
**Before:** Payment information was mixed in the middle of tax calculations:
```
Subtotal: ₹1000
Before Discount: ₹1200
Discount: ₹200 (₹200)
Payment: UNPAID
Paid: ₹0
Due: ₹1000
CGST (9%): ₹90
SGST (9%): ₹90
TOTAL: ₹1180
```

**After:** Clear hierarchy with TOTAL before payment info:
```
Items Total:   ₹1200
Discount:      -₹200 (16.7%)
Taxable Value: ₹1000

CGST (9%):     ₹90
SGST (9%):     ₹90

TOTAL:         ₹1180

Paid:          ₹0
DUE:           ₹1180
```

### Calculation Order (As Per Your Specification)

1. **Items Total** = Sum of all line items (gross, before discount)
2. **Discount** = Applied to Items Total to get Taxable Value
3. **Taxable Value** = Items Total - Discount
4. **Taxes** = CGST (9%) + SGST (9%) OR IGST (18%) on Taxable Value
5. **Grand Total** = Taxable Value + Taxes
6. **Balance Due** = Grand Total - Amount Paid

### Formula Reference

```
Items Total:         $A
Discount:           -$D% = -$DAmount
─────────────────────────
Taxable Value:       $A - $DAmount = $T
CGST (9%):           $T × 0.09 = $CGST
SGST (9%):           $T × 0.09 = $SGST
─────────────────────────
TOTAL (Grand):       $T + $CGST + $SGST = $G
Paid:                $P
─────────────────────────
DUE:                 $G - $P ← FINAL LINE
```

## Invoice Display Template

```
📦 Items:
  • Organic Honey 500g x 2 @ ₹250

💰 Billing Summary:
────────────────────
Items Total:   ₹500
Discount:      -₹50 (10%)
Taxable Value: ₹450

CGST (9%):     ₹40.50
SGST (9%):     ₹40.50

TOTAL:         ₹531

Paid:          ₹0
DUE:           ₹531
────────────────────

📍 State: MH — Intra-State
💳 Status: UNPAID
🆔 `approval-id-here`
```

## Discount Format Fix

### Old Format (Redundant):
- `Discount: 10% (₹200)` — confusing double rupee signs
- `Discount: ₹200` — missing percentage

### New Format (Clean):
- `Discount: -₹200 (10%)` — shows both amount AND percentage clearly
- `Discount: -₹200` — for fixed amount discounts

## Special Cases Handled

### 1. No Discount
```
Items Total:   ₹500
Taxable Value: ₹500

CGST (9%):     ₹45
SGST (9%):     ₹45

TOTAL:         ₹590
```

### 2. Inter-State (IGST) Transaction
```
Items Total:   ₹500
Taxable Value: ₹500

IGST (18%):    ₹90

TOTAL:         ₹590
```

### 3. Unregistered Seller (No GST)
```
Items Total:   ₹500
Taxable Value: ₹500

GST:           None (Unregistered)

TOTAL:         ₹500
```

### 4. Composite Seller (3% GST)
```
Items Total:   ₹500
Taxable Value: ₹500

Composite GST (3%): ₹15

TOTAL:         ₹515
```

### 5. Partial Payment
```
Items Total:   ₹500
Discount:      -₹50 (10%)
Taxable Value: ₹450

CGST (9%):     ₹40.50
SGST (9%):     ₹40.50

TOTAL:         ₹531

Paid:          ₹300
DUE:           ₹231
```

## Integration Points

### Where Formatting is Used
1. `bin/telegram_bot.dart` - Displays invoice approval messages
2. `lib/tools/approval_tools.dart` - Calls `formatApprovalMessage()` before sending
3. Any tool that generates approval preview

### Required Parameters
```dart
formatApprovalMessage(
  approval: DraftApproval,                    // The approval object with proposedTotal
  customerName: String,                        // "Jitu", "Walk-in", etc.
  itemDescriptions: List<String>,              // ["Item x Qty @ Price", ...]
  gstType: String? = 'CGST_SGST',             // 'CGST_SGST' or 'IGST'
  paymentStatus: String? = 'UNPAID',          // 'PAID', 'PARTIAL', 'UNPAID'
  amountPaid: double? = 0.0,                  // Amount customer paid
  dueAmount: double? = null,                  // Auto-calculated if null
  discountType: String? = 'PERCENT',          // 'PERCENT' or 'AMOUNT'
  discountValue: double? = 10.0,              // 10 for 10%, or 200 for ₹200
  discountAmount: double? = null,             // Auto-calculated from type+value
  subtotalBeforeDiscount: double? = null,     // Items Total
  subtotalAfterDiscount: double? = null,      // Taxable Value
)
```

## Validation Rules

### Amount Validation
- All amounts are rounded to 2 decimal places (.00)
- Discount cannot exceed Items Total
- Amount Paid cannot exceed Grand Total
- Due Amount = Grand Total - Amount Paid (always positive or zero)

### Discount Validation
- Percentage discount: 0-100%
- Fixed amount discount: any positive number ≤ Items Total

### Payment Status Logic
- **UNPAID**: amount_paid = 0
- **PARTIAL**: 0 < amount_paid < grand_total
- **PAID**: amount_paid ≥ grand_total (due amount = ₹0)

## Testing Checklist

- [ ] No discount → Shows "Items Total" and "Taxable Value" as same amount
- [ ] 10% discount → Shows "Discount: -₹X (10%)" format
- [ ] UNPAID status → Shows "DUE: ₹[full amount]"
- [ ] PARTIAL payment → Shows "Paid: ₹X" and "DUE: ₹Y"
- [ ] PAID status → Shows "Paid: ₹[full]" and "DUE: ₹0"
- [ ] Inter-state transaction → Shows IGST instead of CGST+SGST
- [ ] Unregistered seller → Shows "GST: None (Unregistered)"
- [ ] Final line is always "DUE" (not sandwiched in middle)

## Code Location

File: `/workspaces/dukansathi-new/lib/services/approval_formatter.dart`

Key Functions:
- `formatApprovalMessage()` - Main invoice formatter (lines 40-130)
- `_formatDiscountLine()` - Discount formatter (lines 10-40)
- `_roundToTwoDecimals()` - Rounding helper (lines 8-9)

## Error Handling

The formatter handles:
- Missing discount values → Shows no discount line
- Missing amount_paid → Defaults to ₹0
- Missing dueAmount → Auto-calculates from grand_total - amount_paid
- Null subtotals → Uses tax breakdown subtotal values

All calculations are defensive and won't throw errors with partial data.
