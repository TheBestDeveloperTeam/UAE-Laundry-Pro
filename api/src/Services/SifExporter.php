<?php

namespace LaundryPro\Api\Services;

class SifExporter
{
    /**
     * Generate a WPS SIF (Salary Information File) string.
     * Standard UAE Central Bank format for SIF files.
     * 
     * @param string $employerRoutingCode 9-digit employer routing code
     * @param string $employerAccountNumber Employer's bank account number
     * @param string $salaryMonth YYYYMM format
     * @param array $employees Array of employee data arrays
     * @return string The SIF file content
     */
    public static function generateSif(
        string $employerRoutingCode, 
        string $employerAccountNumber, 
        string $salaryMonth, 
        array $employees
    ): string {
        $lines = [];
        
        $totalSalaries = 0.0;
        $employeeCount = count($employees);
        
        foreach ($employees as $emp) {
            $empId = str_pad($emp['employee_id'] ?? '', 14, '0', STR_PAD_LEFT);
            $agentRouting = str_pad($emp['agent_routing_code'] ?? '', 9, '0', STR_PAD_LEFT);
            $accountNumber = str_pad($emp['account_number'] ?? '', 23, ' ', STR_PAD_RIGHT);
            $startDate = $emp['start_date'] ?? '        '; // YYYYMMDD or 8 spaces
            $endDate = $emp['end_date'] ?? '        '; // YYYYMMDD or 8 spaces
            $daysOnLeave = str_pad((string)($emp['days_on_leave'] ?? 0), 4, '0', STR_PAD_LEFT);
            
            // Fixed and variable components
            $fixedPay = number_format((float)($emp['fixed_pay'] ?? 0), 2, '.', '');
            $variablePay = number_format((float)($emp['variable_pay'] ?? 0), 2, '.', '');
            
            $totalSalaries += (float)$fixedPay + (float)$variablePay;
            
            // Employee Detail Record (EDR)
            $edr = "EDR," . 
                   $empId . "," . 
                   $agentRouting . "," . 
                   $accountNumber . "," . 
                   $startDate . "," . 
                   $endDate . "," . 
                   $daysOnLeave . "," . 
                   $fixedPay . "," . 
                   $variablePay . "," . 
                   "0"; // 0 for normal, 1 for stop payment, etc.
                   
            $lines[] = $edr;
        }
        
        $totalSalariesStr = number_format($totalSalaries, 2, '.', '');
        $date = date('Y-m-d');
        $time = date('Hi');
        $fileCreationDate = date('Ymd');
        
        // Header Record (SCR)
        $scr = "SCR," . 
               $employerRoutingCode . "," . 
               $employerAccountNumber . "," . 
               $fileCreationDate . "," . 
               $time . "," . 
               $salaryMonth . "," . 
               $employeeCount . "," . 
               $totalSalariesStr . "," . 
               "AED," . 
               "SAL"; // Salary purpose code
               
        // SCR is always the first line
        array_unshift($lines, $scr);
        
        return implode("\r\n", $lines) . "\r\n";
    }
}
