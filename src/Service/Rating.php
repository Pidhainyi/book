<?php

declare(strict_types=1);

namespace App\Service;

class Rating
{
    public function __construct(private readonly int $total, private readonly float $rating)
    {
    }

    public function getTotal(): int
    {
        return $this->total;
    }

    public function getRating(): float
    {
        return $this->rating;
    }
}
