---------- Term Project Part One ----------
-- Jacob Dykstra 5/28/26
-- Execute all statements in this file before executing statements in "CS276_TermProject_FunctionsProcedures&Triggers_JDykstra.sql"

---------------------------------------------
-- 0. Drop and Create database
---------------------------------------------
USE master;
GO

DROP DATABASE IF EXISTS JakesFreeGameBrowser;
GO

CREATE DATABASE JakesFreeGameBrowser;
GO

USE JakesFreeGameBrowser;
GO
---------------------------------------------
-- 1. Create Main Tables (5 tables)
---------------------------------------------
-- User images stored in seprate table because they have noticeable preformance impact
CREATE TABLE UserImages( 
    UserImageID INT IDENTITY(1,1) PRIMARY KEY,
    UserImageData VARBINARY(MAX)
);

-- this table stores main user information
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100) NOT NULL UNIQUE,
    UserEmail NVARCHAR(255) NOT NULL UNIQUE,
    UserDescription NVARCHAR(500) DEFAULT '',
    UserSocialContact NVARCHAR(500) DEFAULT '',
    UserCreationDate DATETIME DEFAULT GETDATE(),
    UserImageId INT,
    CONSTRAINT FK_Users_UserImage FOREIGN KEY (UserImageId) REFERENCES UserImages(UserImageId)
);

-- this table stores informaion on places online where games are sold
CREATE TABLE Stores (
    StoreId INT IDENTITY(1,1) PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    StoreLink NVARCHAR(500)
);

-- this table stores the Genres of games
CREATE TABLE Genres (
    GenreId INT IDENTITY(1,1) PRIMARY KEY,
    GenreName NVARCHAR(50) NOT NULL UNIQUE,
    GenreDescription NVARCHAR(255) NOT NULL
);

-- this table stores main information on games sold and will be very highly used
CREATE TABLE Games (
    GameId INT IDENTITY(1,1) PRIMARY KEY,
    GameName NVARCHAR(255) NOT NULL,
    GameDescription NVARCHAR(MAX),
    GameImageLink NVARCHAR(500),
    GenreId INT,
    LastUpdate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Games_Genres FOREIGN KEY (GenreId) REFERENCES Genres(GenreId)
);
GO

---------------------------------------------
-- 2. Create Bridging Tables (5 tables(
---------------------------------------------
-- this table will store information on user wishlists
-- Wishlist depends on Users (Owner)
CREATE TABLE Wishlists (
    WishlistId INT IDENTITY(1,1) PRIMARY KEY,
    OwnerId INT NOT NULL,
    WishlistName NVARCHAR(100) NOT NULL,
    WishlistDescription NVARCHAR(500) DEFAULT '',
    WishlistCreationDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Wishlist_Users FOREIGN KEY (OwnerId) REFERENCES Users(UserId),
    CONSTRAINT UQ_Wishlists_Name_Owner UNIQUE (OwnerId, WishlistName)
);

-- this table stores information on user relationships (friends or not friends)
-- Friends maps Users to Users
CREATE TABLE Friends (
    FriendPrimary INT NOT NULL,
    FriendSecondary INT NOT NULL,
    FriendDate DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (FriendPrimary, FriendSecondary),
    CONSTRAINT FK_Friends_FriendPrimary FOREIGN KEY (FriendPrimary) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_Friends_FriendSecondary FOREIGN KEY (FriendSecondary) REFERENCES Users(UserId)
);
-- this list stores what games are in what wishlists
-- WishlistGames maps Games to a Wishlist
CREATE TABLE WishlistGames (
    WishlistId INT NOT NULL,
    GameId INT NOT NULL,
    UserAdded INT,
    DateAdded DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (WishlistId, GameId),
    CONSTRAINT FK_WishlistGames_Wishlist FOREIGN KEY (WishlistId) REFERENCES Wishlists(WishlistId) ON DELETE CASCADE,
    CONSTRAINT FK_WishlistGames_Games FOREIGN KEY (GameId) REFERENCES Games(GameId) ON DELETE CASCADE,
    CONSTRAINT FK_WishlistGames_UserAdded FOREIGN KEY (UserAdded) REFERENCES Users(UserId) ON DELETE SET NULL
);

-- this list stores what users can access a wishlist and what level of permission they have
-- WishlistUsers manages permissions (View/Edit) for non-owners
CREATE TABLE WishlistUsers (
    WishlistId INT NOT NULL,
    UserId INT NOT NULL,
    Permission NVARCHAR(4) NOT NULL, -- ex: 'View' or 'Edit'
    DateAdded DateTime Default GetDate(),
    PRIMARY KEY (WishlistId, UserId),
    CONSTRAINT FK_WishlistUsers_Wishlist FOREIGN KEY (WishlistId) REFERENCES Wishlists(WishlistId) ON DELETE CASCADE,
    CONSTRAINT FK_WishlistUsers_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT CHK_Permission_Type CHECK (Permission IN ('edit', 'view'))
);

-- this list stores the price of a game for sale at a store in the Stores table
-- GamePrices maps Games to Stores with price
CREATE TABLE GamePrices (
    GameId INT NOT NULL,
    StoreId INT NOT NULL,
    DefaultPrice DECIMAL(10, 2) NOT NULL,
    DiscountPercent DECIMAL(5, 2) DEFAULT 0.00,
    CheapSharkDealID NVARCHAR(100),
    GameLink NVARCHAR(500),
    PRIMARY KEY (GameId, StoreId),
    CONSTRAINT FK_GamePrices_Games FOREIGN KEY (GameId) REFERENCES Games(GameId)  ON DELETE CASCADE,
    CONSTRAINT FK_GamePrices_Stores FOREIGN KEY (StoreId) REFERENCES Stores(StoreId) 
);
GO

---------------------------------------------
-- 3. Create ArchiveTables (4 tables)
---------------------------------------------
-- this table stores past owners of wishlists if the owner changes
CREATE TABLE WishlistOwnerArchive (
    ArchiveId INT IDENTITY(1,1) PRIMARY KEY,
    WishlistId INT NOT NULL,
    OwnerId INT NOT NULL,
    DateArchived DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_WishlistOwnerArchive_Wishlists FOREIGN KEY (WishlistId) REFERENCES Wishlists(WishlistId)ON DELETE CASCADE,
    CONSTRAINT FK_WishlistOwnerArchive_Users FOREIGN KEY (OwnerId) REFERENCES Users(UserId) ON DELETE CASCADE
);

-- this list stores user account changes to have a backup against people losing their account.
CREATE TABLE UserChangesArchive (
    ArchiveId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Username NVARCHAR(100),
    UserEmail NVARCHAR(255),
    UserDescription NVARCHAR(500),
    UserSocialContact NVARCHAR(500),
    DateArchived DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_UserChangesArchive_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
 );

-- this table stores the date when games are updated or added to the games table
CREATE TABLE ApiUpdateArchive (
    ArchiveId INT IDENTITY(1,1) PRIMARY KEY,
    DateUpdated DATETIME DEFAULT GETDATE(),
);

-- this table stores what games got updated in an update to the games table
CREATE TABLE GamesUpdatedArchive (
    ApiArchiveId INT NOT NULL,
    GameId INT NOT NULL,
    CONSTRAINT FK_GamesUpdatedArchive_ApiUpdateArchive 
        FOREIGN KEY (ApiArchiveId) 
        REFERENCES ApiUpdateArchive(ArchiveId),
    CONSTRAINT FK_GamesUpdatedArchive_Games 
        FOREIGN KEY (GameId) 
        REFERENCES Games(GameId)
        ON DELETE CASCADE
);
GO


---------------------------------------------
-- 4. Create Indexes (9 indexes)
---------------------------------------------
-- Indexes for Foreign Key Performance
CREATE NONCLUSTERED INDEX IX_Games_GenreId 
    ON Games (GenreId);
GO

CREATE NONCLUSTERED INDEX IX_Wishlists_OwnerId 
    ON Wishlists (OwnerId);
GO

CREATE NONCLUSTERED INDEX IX_Friends_FriendSecondary 
    ON Friends (FriendSecondary);
GO

CREATE NONCLUSTERED INDEX IX_WishlistGames_GameId 
    ON WishlistGames (GameId);
GO

CREATE NONCLUSTERED INDEX IX_WishlistGames_UserAdded 
    ON WishlistGames (UserAdded);
GO

CREATE NONCLUSTERED INDEX IX_WishlistUsers_UserId 
    ON WishlistUsers (UserId);
GO

CREATE NONCLUSTERED INDEX IX_GamePrices_StoreId 
    ON GamePrices (StoreId);
GO

-- Indexes for Search Performance
CREATE NONCLUSTERED INDEX IX_Games_GameName 
    ON Games (GameName);
GO

CREATE NONCLUSTERED INDEX IX_Stores_StoreName 
    ON Stores (StoreName);
GO

---------------------------------------------
-- 5. Insert Dummy Data
---------------------------------------------
-- Insert Dummy Users (ImageId is left NULL)
INSERT INTO Users (Username, UserEmail, UserDescription, UserSocialContact)
VALUES 
    ('TestUserOne', 'user1@test.local', 'First test user profile', '@testuser1'),
    ('TestUserTwo', 'user2@test.local', 'Second test user profile', '@testuser2'),
    ('TestUserThree', 'user3@test.local', 'Third test user profile', '@testuser3'),
    ('TestUserFour', 'user4@test.local', 'Fourth test user profile', '@testuser4');

-- Insert Dummy Stores (StoreLink is left blank)
INSERT INTO Stores (StoreName, StoreLink)
VALUES 
    ('Alpha Digital Store', ''),
    ('Beta Games Market', ''),
    ('Gamma Play Store', '')

-- Insert Dummy Genres
INSERT INTO Genres (GenreName, GenreDescription)
VALUES 
    ('Fictional Action', 'Fast paced test games'),
    ('Fictional RPG', 'Role playing test games'),
    ('Fictional Puzzle', 'Brain teasing test games');

-- Insert Dummy Games (GameImageLink is left NULL)
INSERT INTO Games (GameName, GameDescription, GameImageLink, GenreId)
VALUES 
    ('Test Game Alpha', 'A great action testing game', NULL, 1),
    ('Test Game Beta', 'An immersive RPG experience for testing', NULL, 2),
    ('Test Game Gamma', 'A challenging logic puzzle game', NULL, 3),
    ('Test Game Delta', 'Another action thriller for tests', NULL, 1);

-- Insert Dummy Friends (Mapping Users to Users)
INSERT INTO Friends (FriendPrimary, FriendSecondary)
VALUES 
    (1, 2),
    (1, 3),
    (2, 4);

-- Insert Dummy Wishlists
INSERT INTO Wishlists (OwnerId, WishlistName, WishlistDescription)
VALUES 
    (1, 'User One Favorites', 'Top test games for user one'),
    (2, 'User Two Must Haves', 'Games user two wants to test'),
    (3, 'User Three Queue', 'Next games to test for user three');

-- Insert Dummy WishlistGames (Mapping Games to a Wishlist)
INSERT INTO WishlistGames (WishlistId, GameId, UserAdded)
VALUES 
    (1, 1, 1),
    (1, 2, 1),
    (1, 3, 2), -- User 2 collaboratively adding to User 1's list
    (2, 4, 2),
    (3, 1, 3);

-- Insert Dummy WishlistUsers (Permissions for non-owners)
INSERT INTO WishlistUsers (WishlistId, UserId, Permission)
VALUES 
    (1, 2, 'edit'),
    (1, 3, 'view'),
    (2, 1, 'view');

-- Insert Dummy GamePrices (GameLink is left blank)
INSERT INTO GamePrices (GameId, StoreId, DefaultPrice, DiscountPercent, GameLink)
VALUES 
    (1, 1, 59.99, 10.00, ''),
    (1, 2, 59.99, 0.00, ''),
    (2, 1, 49.99, 50.00, ''),
    (3, 3, 19.99, 0.00, ''),
    (4, 2, 29.99, 25.00, '');