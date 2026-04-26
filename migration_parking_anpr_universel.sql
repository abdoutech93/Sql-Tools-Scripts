CREATE TABLE currentpictures (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    plate VARCHAR(20),                -- Ajustez la taille selon vos besoins
    Picture LONGBLOB,                 -- Stockage de l'image principale
    PlatePicture LONGBLOB,            -- Stockage de l'image de la plaque
    pic_size INT,                     -- Taille en octets ou dimensions
    plate_pic_size INT,               -- Taille en octets ou dimensions
    time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE `database_manager`.`parkingaccesslog` 
ADD COLUMN `QuitPlatePicture` LONGBLOB NULL AFTER `lpnOUT`;

ALTER TABLE `database_manager`.`parkingaccesslog` 
ADD COLUMN `PlatePicture` LONGBLOB NULL AFTER `lpnOUT`;


ALTER TABLE `database_manager`.`parkingaccesslog` 
ADD COLUMN `plate_pic_size` INT NOT NULL DEFAULT 0 ;

ALTER TABLE `database_manager`.`parkingaccesslog` 
CHANGE COLUMN `observation` `observation` TEXT NOT NULL DEFAULT '' ;

ALTER TABLE `database_manager`.`currentpictures` 
ADD COLUMN `plate_pic_size` INT NOT NULL DEFAULT 0 AFTER `plate`;

ALTER TABLE `database_manager`.`currentpictures` 
ADD COLUMN `PlatePicture` LONGBLOB NULL AFTER `plate`;
