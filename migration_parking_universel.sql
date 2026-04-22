ALTER TABLE `database_manager`.`parkingaccesslog` 
ADD COLUMN `QuitPlatePicture` LONGBLOB NULL AFTER `lpnOUT`;

ALTER TABLE `database_manager`.`parkingaccesslog` 
ADD COLUMN `PlatePicture` LONGBLOB NULL AFTER `lpnOUT`;


ALTER TABLE `database_manager`.`currentpictures` 
ADD COLUMN `plate_pic_size` INT NOT NULL DEFAULT 0 AFTER `plate`;

ALTER TABLE `database_manager`.`currentpictures` 
ADD COLUMN `PlatePicture` LONGBLOB NULL AFTER `plate`;
