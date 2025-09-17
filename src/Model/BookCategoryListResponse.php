<?php

declare(strict_types=1);

namespace App\Model;

readonly class BookCategoryListResponse
{
    /**
     * @param BookCategory[] $items
     */
    public function __construct(private array $items)
    {
    }

    /**
     * @return BookCategory[]
     */
    public function getItems(): array
    {
        return $this->items;
    }
}
