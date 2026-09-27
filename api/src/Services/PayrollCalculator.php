<?php

namespace LaundryPro\Api\Services;

class PayrollCalculator
{
    private const OVERTIME_REGULAR_MULTIPLIER = 1.25;
    private const OVERTIME_REST_DAY_MULTIPLIER = 1.50;
    private const OVERTIME_PUBLIC_HOLIDAY_MULTIPLIER = 2.00;

    /**
     * Calculate overtime pay according to UAE Labor Law.
     * Basic salary is used as the base for overtime calculation.
     *
     * @param float $basicSalary The employee's monthly basic salary
     * @param int $regularOvertimeHours Hours worked beyond regular hours on normal days
     * @param int $restDayOvertimeHours Hours worked on weekends/rest days
     * @param int $holidayOvertimeHours Hours worked on public holidays
     * @return float The total overtime pay
     */
    public static function calculateOvertime(
        float $basicSalary,
        int $regularOvertimeHours = 0,
        int $restDayOvertimeHours = 0,
        int $holidayOvertimeHours = 0
    ): float {
        // Assuming 30 days a month and 8 hours a day for hourly rate calculation
        $hourlyRate = ($basicSalary / 30) / 8;

        $regularPay = $hourlyRate * self::OVERTIME_REGULAR_MULTIPLIER * $regularOvertimeHours;
        $restDayPay = $hourlyRate * self::OVERTIME_REST_DAY_MULTIPLIER * $restDayOvertimeHours;
        $holidayPay = $hourlyRate * self::OVERTIME_PUBLIC_HOLIDAY_MULTIPLIER * $holidayOvertimeHours;

        return round($regularPay + $restDayPay + $holidayPay, 2);
    }

    /**
     * Calculate End of Service Gratuity (UAE Labor Law).
     *
     * @param float $basicSalary The employee's latest basic salary
     * @param int $yearsOfService Number of full years worked
     * @param int $remainingDays Remaining days worked beyond full years
     * @return float The calculated gratuity amount
     */
    public static function calculateGratuity(float $basicSalary, int $yearsOfService, int $remainingDays = 0): float
    {
        // Gratuity rules:
        // 1. Less than 1 year: 0
        // 2. 1 to 5 years: 21 days basic salary per year
        // 3. Above 5 years: 21 days for first 5 years + 30 days for each additional year
        // Max gratuity cannot exceed 2 years' gross salary.

        if ($yearsOfService < 1) {
            return 0.0;
        }

        $dailyRate = $basicSalary / 30;
        $gratuityDays = 0;

        if ($yearsOfService <= 5) {
            $gratuityDays = $yearsOfService * 21;
        } else {
            $gratuityDays = (5 * 21) + (($yearsOfService - 5) * 30);
        }

        // Add pro-rata for remaining days
        if ($yearsOfService <= 5) {
            $gratuityDays += ($remainingDays / 365) * 21;
        } else {
            $gratuityDays += ($remainingDays / 365) * 30;
        }

        $gratuityAmount = $gratuityDays * $dailyRate;

        // Cap at 2 years gross salary (assuming basic salary is a reasonable proxy for cap check,
        // though strictly it's gross salary, we use basic * 24 as a safe fallback if gross isn't provided)
        $maxGratuity = $basicSalary * 24;

        return round(min($gratuityAmount, $maxGratuity), 2);
    }
}
