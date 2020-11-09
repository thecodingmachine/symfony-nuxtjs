<?php
/*
 * This file has been automatically generated by TDBM.
 * You can edit this file as it will not be overwritten.
 */

declare(strict_types=1);

namespace App\Domain\Model;

use App\Domain\Constraint as DomainAssert;
use App\Domain\Model\Generated\BaseCompany;
use Symfony\Component\Validator\Constraints as Assert;
use TheCodingMachine\GraphQLite\Annotations\Field;
use TheCodingMachine\GraphQLite\Annotations\Type;

/**
 * The Company class maps the 'companies' table in database.
 *
 * @Type
 * @DomainAssert\Unicity(table="companies", column="name", message="company.name_not_unique")
 */
class Company extends BaseCompany
{
    /**
     * @Field
     * @Assert\NotBlank(message="not_blank")
     * @Assert\Length(max=255, maxMessage="max_length_255")
     */
    public function getName(): string
    {
        return parent::getName();
    }

    /**
     * @Field
     * @Assert\NotBlank(allowNull=true, message="not_blank")
     * @Assert\Length(max=255, maxMessage="max_length_255")
     * @Assert\Url(message="invalid_url")
     */
    public function getWebsite(): ?string
    {
        return parent::getWebsite();
    }

    /**
     * @Field
     * @Assert\Expression("this.getUser().getRole() === 'MERCHANT'", message="company.user_not_a_merchant")
     */
    public function getUser(): User
    {
        return parent::getUser();
    }
}