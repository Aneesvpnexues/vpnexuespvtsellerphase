package com.vpnex.backend.service;

import com.vpnex.backend.dto.IfscVerifyResponse;
import java.util.Map;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;

/**
 * IFSC validation.
 *
 * <p>The Flutter screen's inline Verify button always succeeds —
 * {@code _ifscIsValid => true} in {@code lib/screens/bank_detaile.dart} — so
 * this is the first check that actually rejects a bad code.
 *
 * <p>Current behaviour is format validation plus a small bank-code table for
 * the eight banks the app offers in its picker. Swap {@link #lookup} for a call
 * to the Razorpay/BankBazaar IFSC API when live payouts need the branch name
 * confirmed; the signature already returns everything the UI needs.
 */
@Service
public class IfscService {

  private static final Pattern IFSC_PATTERN = Pattern.compile("^[A-Z]{4}0[A-Z0-9]{6}$");

  /** IFSC prefix -> bank name, for the banks in the app's picker. */
  private static final Map<String, String> BANK_PREFIXES =
      Map.ofEntries(
          Map.entry("SBIN", "State Bank of India"),
          Map.entry("HDFC", "HDFC Bank"),
          Map.entry("ICIC", "ICICI Bank"),
          Map.entry("UTIB", "Axis Bank"),
          Map.entry("KKBK", "Kotak Mahindra Bank"),
          Map.entry("PUNB", "Punjab National Bank"),
          Map.entry("BARB", "Bank of Baroda"),
          Map.entry("CNRB", "Canara Bank"));

  public boolean isValidFormat(String ifsc) {
    return ifsc != null && IFSC_PATTERN.matcher(ifsc.trim().toUpperCase()).matches();
  }

  public IfscVerifyResponse lookup(String rawIfsc) {
    String ifsc = rawIfsc == null ? "" : rawIfsc.trim().toUpperCase();

    if (!isValidFormat(ifsc)) {
      return new IfscVerifyResponse(
          false, ifsc, null, null,
          "IFSC must be 11 characters: 4 letters, then 0, then 6 letters or digits.");
    }

    String bankName = BANK_PREFIXES.get(ifsc.substring(0, 4));
    if (bankName == null) {
      // Well-formed but not one of the eight banks the app ships with. Accept
      // it — the seller may bank somewhere else — but report the code as-is.
      bankName = null;
    }
    return new IfscVerifyResponse(true, ifsc, bankName, null, "IFSC looks valid.");
  }
}
