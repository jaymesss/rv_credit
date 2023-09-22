# rv_credit

1. Run this query on your MySQL database:

CREATE TABLE `creditloans` (
	`id` INT(11) NULL DEFAULT NULL,
	`citizenid` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`fullname` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`name` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`amount` BIGINT(20) NULL DEFAULT NULL,
	`interest` INT(11) NULL DEFAULT NULL,
	`paymentsleft` INT(11) NULL DEFAULT NULL,
	`totalpayments` INT(11) NULL DEFAULT NULL,
	`lastpaymenttime` BIGINT(20) NULL DEFAULT NULL,
	`notes` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci'
);

CREATE TABLE `creditloanhistory` (
	`fullname` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`name` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
	`amount` BIGINT(20) NULL DEFAULT NULL
);

2. Copy the image in the /images directory to `qb-inventory/html/images`

3. Add the following to your qb-core/shared/items.lua:

['banker_tablet'] = {['name'] = 'banker_tablet', ['label'] = 'Banker Tablet', ['weight'] = 100, ['type'] = 'item', ['image'] = 'banker_tablet.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'View all of the bonds up for grabs!'},

4. Add the following to your qb-core/shared/jobs.lua:

['banker'] = {
    label = 'Banker',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = {
            name = 'Employee',
            payment = 30
        },
        ['1'] = {
            name = 'Boss',
            payment = 60,
            isboss = true
        },
    },
},