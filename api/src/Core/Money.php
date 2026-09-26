<?php

namespace LaundryPro\Api\Core;

use InvalidArgumentException;

/**
 * Money
 * 
 * A strict wrapper around bcmath for precise monetary calculations.
 * Enforces a scale of 2 decimal places everywhere.
 * Raw floating point operations (+, -, *, /) must NEVER be used for monetary values.
 */
class Money
{
    private const SCALE = 2;

    private string $amount;

    /**
     * @param string|int|float $amount
     */
    public function __construct($amount)
    {
        $this->amount = self::format((string)$amount);
    }

    /**
     * Format a number string to exactly 2 decimal places.
     */
    private static function format(string $amount): string
    {
        if (!is_numeric($amount)) {
            throw new InvalidArgumentException("Money amount must be numeric, got: {$amount}");
        }
        // Use bcadd with 0 to safely enforce scale without altering value
        return bcadd($amount, '0', self::SCALE);
    }

    public function getAmount(): string
    {
        return $this->amount;
    }

    /**
     * Add another money value.
     */
    public function add(Money $other): Money
    {
        return new self(bcadd($this->amount, $other->getAmount(), self::SCALE));
    }

    /**
     * Subtract another money value.
     */
    public function subtract(Money $other): Money
    {
        return new self(bcsub($this->amount, $other->getAmount(), self::SCALE));
    }

    /**
     * Multiply by a scalar multiplier.
     */
    public function multiply(string $multiplier): Money
    {
        if (!is_numeric($multiplier)) {
            throw new InvalidArgumentException("Multiplier must be numeric");
        }
        return new self(bcmul($this->amount, $multiplier, self::SCALE));
    }

    /**
     * Divide by a scalar divisor.
     */
    public function divide(string $divisor): Money
    {
        if (!is_numeric($divisor) || bccomp($divisor, '0', self::SCALE) === 0) {
            throw new InvalidArgumentException("Divisor must be numeric and non-zero");
        }
        return new self(bcdiv($this->amount, $divisor, self::SCALE));
    }

    /**
     * Compare to another money value.
     * Returns 0 if equal, 1 if $this > $other, -1 if $this < $other.
     */
    public function compareTo(Money $other): int
    {
        return bccomp($this->amount, $other->getAmount(), self::SCALE);
    }

    public function equals(Money $other): bool
    {
        return $this->compareTo($other) === 0;
    }

    public function greaterThan(Money $other): bool
    {
        return $this->compareTo($other) === 1;
    }

    public function lessThan(Money $other): bool
    {
        return $this->compareTo($other) === -1;
    }

    public function greaterThanOrEqual(Money $other): bool
    {
        return $this->compareTo($other) >= 0;
    }

    public function lessThanOrEqual(Money $other): bool
    {
        return $this->compareTo($other) <= 0;
    }

    public function __toString(): string
    {
        return $this->amount;
    }
}
