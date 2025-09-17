<?php

declare(strict_types=1);

namespace App\Model;

readonly class RecommendedBookListResponse
{
    /**
     * @param RecommendedBook[] $items
     */
    public function __construct(private array $items)
    {
    }

    /**
     * @return RecommendedBook[]
     */
    public function getItems(): array
    {
        return $this->items;
    }
}
