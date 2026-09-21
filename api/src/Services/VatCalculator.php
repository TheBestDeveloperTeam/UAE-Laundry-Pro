<?php

namespace LaundryPro\Api\Services;

class VatCalculator
{
    private const VAT_RATE = '0.05';

    /**
     * Calculate VAT from a net amount.
     * 
     * @param string|float $netAmount The net amount before VAT
     * @return string The VAT amount (rounded to 2 decimal places, half up)
     */
    public static function calculateVat(string|float $netAmount): string
    {
        $amount = is_float($netAmount) ? number_format($netAmount, 4, '.', '') : $netAmount;
        $vat = bcmul((string)$amount, self::VAT_RATE, 4);
        
        // Round half up to 2 decimal places
        return self::roundHalfUp($vat, 2);
    }

    /**
     * Calculate VAT from a gross amount (amount including VAT).
     * 
     * @param string|float $grossAmount The gross amount
     * @return string The VAT portion of the gross amount
     */
    public static function calculateVatFromGross(string|float $grossAmount): string
    {
        $amount = is_float($grossAmount) ? number_format($grossAmount, 4, '.', '') : $grossAmount;
        // VAT = Gross * (VAT_RATE / (1 + VAT_RATE))
        // 0.05 / 1.05 = 0.047619047...
        $rateFraction = bcdiv(self::VAT_RATE, bcadd('1', self::VAT_RATE, 4), 6);
        $vat = bcmul((string)$amount, $rateFraction, 4);
        
        return self::roundHalfUp($vat, 2);
    }

    private static function roundHalfUp(string $value, int $precision): string
    {
        // bcmath does not natively support round half up easily without workarounds
        // We can use native round() since we just need 2 decimal places for AED currency
        return number_format(round((float)$value, $precision, PHP_ROUND_HALF_UP), $precision, '.', '');
    }
}
