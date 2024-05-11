CREATE TABLE `npcguards` (
	id INT auto_increment NOT NULL,
	fraction_name varchar(255) NOT NULL,
	relations_data TEXT DEFAULT '{}' NULL,
	CONSTRAINT npcguards_pk PRIMARY KEY (id)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_general_ci;
