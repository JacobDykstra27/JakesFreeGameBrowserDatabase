---------- Term Project Part Two ----------
-- Jacob Dykstra 5/28/26
-- Execute all statements in "CS276_TermProject_CreateTables_JDykstra.sql" before executing this file.

USE JakesFreeGameBrowser;
GO

---------------------------------------------
-- 1. Create Procedures (12 Procedures)
---------------------------------------------
-- p_CreateWishlist: Securely inserts a new record into the Wishlists table.
CREATE OR ALTER PROCEDURE p_CreateWishlist
    @OwnerId INT,
    @WishlistName NVARCHAR(100),
    @WishlistDescription NVARCHAR(500) = ''
AS BEGIN
    SET NOCOUNT ON; -- recommended to improve preformace and clean up logs
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @OwnerId)
        THROW 50010, 'The specified OwnerId does not exist in the Users table.', 1;
    IF EXISTS (SELECT 1 FROM Wishlists WHERE OwnerId = @OwnerId AND WishlistName = @WishlistName)
        THROW 50011, 'This user already has a wishlist with this name.', 1;
    BEGIN TRY
        INSERT INTO Wishlists (OwnerId, WishlistName, WishlistDescription)
        VALUES (@OwnerId, @WishlistName, @WishlistDescription);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- TEST p_CreateWishlist & VERIFY
BEGIN TRY
    EXEC p_CreateWishlist @OwnerId = 4, @WishlistName = 'User Four Queue', @WishlistDescription = 'Games I want to test';
    PRINT '--- Verification for p_CreateWishlist ---';
    SELECT WishlistId, OwnerId, WishlistName, WishlistDescription FROM Wishlists WHERE OwnerId = 4 AND WishlistName = 'User Four Queue';
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_AddGame: Securely inserts a new record into the Games table.
CREATE OR ALTER PROCEDURE p_AddGame
    @GameName NVARCHAR(255),
    @GameDescription NVARCHAR(MAX) = NULL,
    @GameImageLink NVARCHAR(500) = NULL,
    @GenreId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Games (GameName, GameDescription, GameImageLink, GenreId)
    VALUES (@GameName, @GameDescription, @GameImageLink, @GenreId);
END;
GO

-- TEST p_AddGame & VERIFY
BEGIN TRY
    EXEC p_AddGame @GameName = 'Test Game Epsilon', @GameDescription = 'Added via SP Test', @GenreId = 1;
    PRINT '--- Verification for p_AddGame ---';
    SELECT GameId, GameName, GameDescription FROM Games WHERE GameName = 'Test Game Epsilon';
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_AddUser: Inserts a new user record into the Users table.
CREATE OR ALTER PROCEDURE p_AddUser
    @Username NVARCHAR(100),
    @UserEmail NVARCHAR(255),
    @UserDescription NVARCHAR(500) = '',
    @UserSocialContact NVARCHAR(500) = '',
    @UserImageId INT = NULL
AS BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
        THROW 50005, 'Username is already taken.', 1;
    IF EXISTS (SELECT 1 FROM Users WHERE UserEmail = @UserEmail)
        THROW 50006, 'Email is already registered.', 1;
    BEGIN TRY
        INSERT INTO Users (Username, UserEmail, UserDescription, UserSocialContact, UserImageId)
        VALUES (@Username, @UserEmail, @UserDescription, @UserSocialContact, @UserImageId);
    END TRY
    BEGIN CATCH
        THROW; 
    END CATCH
END;
GO

-- TEST p_AddUser & VERIFY
BEGIN TRY
    EXEC p_AddUser @Username = 'TestUserFive', @UserEmail = 'user5@test.local', @UserDescription = 'Fifth test user';
    PRINT '--- Verification for p_AddUser ---';
    SELECT UserId, Username, UserEmail FROM Users WHERE Username = 'TestUserFive';
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_AddFriend: Creates a relationship mapping in the Friends table between two users.
CREATE OR ALTER PROCEDURE p_AddFriend
    @FriendPrimary INT,
    @FriendSecondary INT
AS BEGIN
    SET NOCOUNT ON;
    IF @FriendPrimary = @FriendSecondary
        THROW 50012, 'A user cannot friend themselves.', 1;
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @FriendPrimary) OR 
       NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @FriendSecondary)
        THROW 50013, 'One or both users do not exist.', 1;
    IF EXISTS (SELECT 1 FROM Friends WHERE FriendPrimary = @FriendPrimary AND FriendSecondary = @FriendSecondary) OR
       EXISTS (SELECT 1 FROM Friends WHERE FriendPrimary = @FriendSecondary AND FriendSecondary = @FriendPrimary)
        THROW 50014, 'This friendship already exists.', 1;
    BEGIN TRY
        INSERT INTO Friends (FriendPrimary, FriendSecondary)
        VALUES (@FriendPrimary, @FriendSecondary);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- TEST p_AddFriend & VERIFY
BEGIN TRY
    -- Adding friendship between User 3 and User 4
    EXEC p_AddFriend @FriendPrimary = 3, @FriendSecondary = 4;
    PRINT '--- Verification for p_AddFriend ---';
    SELECT * FROM Friends WHERE FriendPrimary = 3 AND FriendSecondary = 4;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_AddGameToWishlist: Maps a Game to a Wishlist, tracking who added it.
CREATE OR ALTER PROCEDURE p_AddGameToWishlist
    @WishlistId INT,
    @GameId INT,
    @UserAdded INT
AS BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Wishlists WHERE WishlistId = @WishlistId)
        THROW 50015, 'The specified Wishlist does not exist.', 1;
    IF NOT EXISTS (SELECT 1 FROM Games WHERE GameId = @GameId)
        THROW 50016, 'The specified Game does not exist.', 1;
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserAdded)
        THROW 50017, 'The user attempting to add the game does not exist.', 1;
    IF NOT EXISTS (SELECT 1 FROM WishlistUsers WHERE UserId = @UserAdded AND WishlistId = @WishlistId AND Permission = 'edit')
       AND NOT EXISTS (SELECT 1 FROM Wishlists WHERE WishlistId = @WishlistId AND OwnerId = @UserAdded) -- Allowing the owner to add it
        THROW 50099, 'The user attempting to add the game does not have permission to edit this wishlist', 1;
    IF EXISTS (SELECT 1 FROM WishlistGames WHERE WishlistId = @WishlistId AND GameId = @GameId)
        THROW 50018, 'This game is already in the specified wishlist.', 1;
    BEGIN TRY
        INSERT INTO WishlistGames (WishlistId, GameId, UserAdded)
        VALUES (@WishlistId, @GameId, @UserAdded);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- TEST p_AddGameToWishlist & VERIFY
BEGIN TRY
    -- User 1 adding Game 4 to Wishlist 1 (Owned by User 1)
    EXEC p_AddGameToWishlist @WishlistId = 1, @GameId = 4, @UserAdded = 1;
    PRINT '--- Verification for p_AddGameToWishlist ---';
    SELECT * FROM WishlistGames WHERE WishlistId = 1 AND GameId = 4;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_RollbackWishlistOwner: Reverts the ownership transfer of a wishlist to its previous iteration. 
CREATE OR ALTER PROCEDURE p_RollbackWishlistOwner
    @WishlistId INT
AS BEGIN
    BEGIN TRY
        SET NOCOUNT ON;
        DECLARE @PreviousOwnerId INT;
        SELECT TOP 1 @PreviousOwnerId = OwnerId
            FROM WishlistOwnerArchive
            WHERE WishlistId = @WishlistId
            ORDER BY DateArchived DESC;
        IF @PreviousOwnerId IS NULL
            THROW 50097, 'Previous Owner Id is null', 1
        IF NOT EXISTS (SELECT UserId FROM Users WHERE UserId = @PreviousOwnerId)
            THROW 50098, 'Previous Owner Id does not exist in users table', 1
        UPDATE Wishlists
            SET OwnerId = @PreviousOwnerId
            WHERE WishlistId = @WishlistId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

-- TEST p_RollbackWishlistOwner & VERIFY
BEGIN TRY
    INSERT INTO WishlistOwnerArchive(WishlistID, OwnerId) VALUES(3,4);
    EXEC p_RollbackWishlistOwner @WishlistId = 3
    SELECT WishlistId, OwnerId as [RestoredOwnerId] FROM Wishlists WHERE WishlistId = 3;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_RollbackAccountChanges: Reverts a user profile to its most recently archived state from UserChangesArchive.
CREATE OR ALTER PROCEDURE p_RollbackAccountChanges
    @UserId INT
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @ArchiveId INT,
            @Username NVARCHAR(100),
            @UserEmail NVARCHAR(255),
            @UserDescription NVARCHAR(500),
            @UserSocialContact NVARCHAR(500),
            @UserCreationDate DATETIME;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP 1 
            @ArchiveId = ArchiveId,
            @Username = Username,
            @UserEmail = UserEmail,
            @UserDescription = UserDescription,
            @UserSocialContact = UserSocialContact
        FROM UserChangesArchive
        WHERE UserId = @UserId
        ORDER BY ArchiveId DESC;

        IF @ArchiveId IS NOT NULL
        BEGIN
            UPDATE Users
            SET Username = @Username,
                UserEmail = @UserEmail,
                UserDescription = @UserDescription,
                UserSocialContact = @UserSocialContact,
                UserCreationDate = @UserCreationDate
            WHERE UserId = @UserId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- TEST p_RollbackAccountChanges & VERIFY
BEGIN TRY
    -- Trigger an archive first
    INSERT INTO UserChangesArchive(UserId,Username, UserEmail,UserDescription,UserSocialContact) 
    VALUES(2, 'TestUserTwo', 'user2@test.local', 'Second test user profile ARCHIVED', '@testuser2')

    -- Rollback
    EXEC p_RollbackAccountChanges @UserId = 2;
    
    SELECT UserId, UserDescription as [RestoredDescription] FROM Users WHERE UserId = 2;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- TransferWishlistOwnership: transfer ownership of wishlist with transaction
CREATE OR ALTER PROCEDURE p_TransferWishlistOwnership
    @WishlistId INT,
    @NewOwnerId INT
AS BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Wishlists WHERE WishlistId = @WishlistId)
            THROW 50003, 'Wishlist does not exist.', 1;
        IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @NewOwnerId)
            THROW 50004, 'New owner does not exist.', 1;
        UPDATE Wishlists
        SET OwnerId = @NewOwnerId
        WHERE WishlistId = @WishlistId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- TEST TransferWishlistOwnership & VERIFY
BEGIN TRY
    -- Transfer Wishlist 2 from User 2 to User 3
    EXEC P_TransferWishlistOwnership @WishlistId = 2, @NewOwnerId = 3;
    PRINT '--- Verification for TransferWishlistOwnership ---';
    SELECT WishlistId, OwnerId AS [NewOwnerId] FROM Wishlists WHERE WishlistId = 2;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_RemoveGameFromWishlist: Removes a game from wishlist
CREATE OR ALTER PROCEDURE p_RemoveGameFromWishlist
    @WishlistId INT,
    @GameId INT,
    @UserRemoving INT
AS BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Wishlists WHERE WishlistId = @WishlistId)
        THROW 50015, 'The specified Wishlist does not exist.', 1;
    IF NOT EXISTS (SELECT 1 FROM Games WHERE GameId = @GameId)
        THROW 50016, 'The specified Game does not exist.', 1;
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserRemoving)
        THROW 50017, 'The user attempting to add the game does not exist.', 1;
    IF NOT EXISTS (SELECT 1 FROM WishlistUsers WHERE UserId = @UserRemoving AND WishlistId = @WishlistId AND Permission = 'edit')
       AND NOT EXISTS (SELECT 1 FROM Wishlists WHERE WishlistId = @WishlistId AND OwnerId = @UserRemoving)
        THROW 50099, 'The user attempting to add the game does not have permission to edit this wishlist', 1;
    IF NOT EXISTS (SELECT 1 FROM WishlistGames WHERE WishlistId = @WishlistId AND GameId = @GameId)
        THROW 50020, 'The specified game is not currently in this wishlist.', 1;
    BEGIN TRY
        DELETE FROM WishlistGames
        WHERE WishlistId = @WishlistId 
          AND GameId = @GameId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- TEST p_RemoveGameFromWishlist & VERIFY
BEGIN TRY
    -- Remove Game 1 from Wishlist 1 (Owned by User 1)
    EXEC p_RemoveGameFromWishlist @WishlistId = 1, @GameId = 1, @UserRemoving = 1;
    PRINT '--- Verification for p_RemoveGameFromWishlist ---';
    SELECT * FROM WishlistGames WHERE WishlistId = 1 AND GameId = 1; -- Should return empty
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_RemoveFriend: Removes a friend entry
CREATE OR ALTER PROCEDURE p_RemoveFriend
    @FriendOne INT,
    @FriendTwo INT
AS BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.Friends 
        WHERE (FriendPrimary = @FriendOne AND FriendSecondary = @FriendTwo)
           OR (FriendPrimary = @FriendTwo AND FriendSecondary = @FriendOne)
        )
        THROW 50021, 'These users are not currently friends.', 1;
    BEGIN TRY
        DELETE FROM dbo.Friends
        WHERE (FriendPrimary = @FriendOne AND FriendSecondary = @FriendTwo)
           OR (FriendPrimary = @FriendTwo AND FriendSecondary = @FriendOne);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- TEST p_RemoveFriend & VERIFY
BEGIN TRY
    EXEC p_RemoveFriend @FriendOne = 1, @FriendTwo = 2;
    SELECT * FROM Friends WHERE (FriendPrimary = 1 AND FriendSecondary = 2) OR (FriendPrimary = 2 AND FriendSecondary = 1);
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_RemoveWishlistUser: Removes a users access to a wishlist
CREATE OR ALTER PROCEDURE p_RemoveWishlistUser
    @WishlistId INT,
    @UserId INT
AS BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.WishlistUsers WHERE WishlistId = @WishlistId AND UserId = @UserId)
        THROW 50022, 'The specified user does not have permission records for this wishlist.', 1;
    BEGIN TRY
        DELETE FROM WishlistUsers
        WHERE WishlistId = @WishlistId 
          AND UserId = @UserId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- TEST p_RemoveWishlistUser & VERIFY
BEGIN TRY
    -- User 3 accesses Wishlist 1 - let's remove them
    EXEC p_RemoveWishlistUser @WishlistId = 1, @UserId = 3;
    SELECT * FROM WishlistUsers WHERE WishlistId = 1 AND UserId = 3; -- Should return zero rows
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO

-- p_PurgeOldArchives: Delete old archives
CREATE OR ALTER PROCEDURE p_PurgeOldArchives
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @CutoffDate DATETIME = DATEADD(YEAR, -1, GETDATE());
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Purge Old Wishlist Ownership Archives
        DELETE FROM dbo.WishlistOwnerArchive
        WHERE DateArchived < @CutoffDate;
        -- Purge Old API Updates 
        DELETE FROM dbo.ApiUpdateArchive
        WHERE DateUpdated < @CutoffDate;
        -- Purge Old User Change Archives
        DELETE FROM dbo.UserChangesArchive
        WHERE DateArchived < @CutoffDate;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- TEST p_PurgeOldArchives & VERIFY
BEGIN TRY
    INSERT INTO dbo.UserChangesArchive (UserId, Username, UserEmail, UserDescription, UserSocialContact, DateArchived)
    VALUES (
        1,
        'PurgeTestUser', 
        'purgetest@test.local', 
        'Testing purge old archives procedure', 
        '@purgetest', 
        DATEADD(YEAR, -2, GETDATE())
    );
    SELECT COUNT(*) AS [OldArchivesBeforeEXEC] FROM dbo.UserChangesArchive WHERE DateArchived < DATEADD(YEAR, -1, GETDATE());
    EXEC p_PurgeOldArchives;
    SELECT COUNT(*) AS [OldArchivesRemaining] FROM dbo.UserChangesArchive WHERE DateArchived < DATEADD(YEAR, -1, GETDATE());
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO


---------------------------------------------
-- 2. Create Triggers (5 Triggers)
---------------------------------------------
-- tr_ArchiveWishlistOwner: Archives old wishlist owner information when the OwnerId changes.
CREATE OR ALTER TRIGGER tr_ArchiveWishlistOwner
    ON Wishlists
    AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    IF UPDATE(OwnerId)
    BEGIN
        INSERT INTO WishlistOwnerArchive (WishlistId, OwnerId)
        SELECT d.WishlistId, d.OwnerId
        FROM deleted d
        INNER JOIN inserted i ON d.WishlistId = i.WishlistId
        WHERE d.OwnerId <> i.OwnerId; -- Only capture actual owner changes
    END
END;
GO

-- TEST tr_ArchiveWishlistOwner & VERIFY
BEGIN TRY
    UPDATE Wishlists SET OwnerId = 3 Where WishlistId = 1;
    SELECT TOP 1 * FROM WishlistOwnerArchive ORDER BY ArchiveId DESC;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO
UPDATE Wishlists SET OwnerId = 1 Where WishlistId = 1; -- reset withlist 1 for future test
GO


-- tr_ArchiveUserEdits: Captures and logs the previous state of a user's profile before an update occurs.
CREATE OR ALTER TRIGGER tr_ArchiveUserEdits
    ON Users
    AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    INSERT INTO UserChangesArchive (UserId, Username, UserEmail, UserDescription, UserSocialContact)
    SELECT d.UserId, d.Username, d.UserEmail, d.UserDescription, d.UserSocialContact
    FROM deleted d
    -- Prevents infinite trigger looping if the rollback SP executes an update
    INNER JOIN inserted i ON d.UserId = i.UserId 
    WHERE d.Username <> i.Username 
       OR d.UserEmail <> i.UserEmail 
       OR ISNULL(d.UserDescription, '') <> ISNULL(i.UserDescription, '')
       OR ISNULL(d.UserSocialContact, '') <> ISNULL(i.UserSocialContact, '');
END;
GO

-- TEST tr_ArchiveUserEdits & VERIFY
BEGIN TRY
    UPDATE Users SET UserSocialContact = '@changed' WHERE UserId = 4;
    SELECT TOP 1 UserId, Username, UserSocialContact AS [ArchivedContact] FROM UserChangesArchive WHERE UserId = 4 ORDER BY ArchiveId DESC;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO


-- tr_ArchiveGameUpdates: Logs batched game updates (e.g., via API) and tracks which specific games were modified.
CREATE OR ALTER TRIGGER tr_ArchiveGameUpdates
    ON Games
    AFTER INSERT, UPDATE
AS BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        DECLARE @ApiArchiveId INT;     
        -- Needs a table variable to capture OUTPUT when inserting default values
        DECLARE @InsertedArchive TABLE (ArchiveId INT);
        -- Create the master archive record for this update batch
        INSERT INTO ApiUpdateArchive (DateUpdated)
        OUTPUT inserted.ArchiveId INTO @InsertedArchive
        DEFAULT VALUES;
        SELECT TOP 1 @ApiArchiveId = ArchiveId FROM @InsertedArchive;
        -- Create the specific child records for each game updated in the batch
        INSERT INTO GamesUpdatedArchive (ApiArchiveId, GameId)
        SELECT @ApiArchiveId, i.GameId 
        FROM inserted i;
    END
END;
GO

-- TEST tr_ArchiveGameUpdates & VERIFY
BEGIN TRY
    UPDATE Games SET GameDescription = 'Trigger testing game description!' WHERE GameId = 2;
    SELECT TOP 1 g.GameId, a.DateUpdated 
    FROM GamesUpdatedArchive g 
    INNER JOIN ApiUpdateArchive a ON g.ApiArchiveId = a.ArchiveId 
    ORDER BY a.ArchiveId DESC;
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO


-- tr_User_Delete_Change_Wishlist_Owner: when user deleted, if wishlists have editors then make oldest editor the owner (use transfer procedure)
CREATE OR ALTER TRIGGER tr_User_Delete_Change_Wishlist_Owner
    ON Users
    INSTEAD OF DELETE
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @WishlistId INT;
    DECLARE @NewOwnerId INT;
    -- Using a cursor to process wishlists one by one so we can call the SP
    DECLARE wishlist_cursor CURSOR FOR
    SELECT 
        w.WishlistId,
        (SELECT TOP 1 wu.UserId 
         FROM WishlistUsers wu 
         WHERE wu.WishlistId = w.WishlistId 
           AND wu.Permission = 'edit' 
           AND wu.UserId NOT IN (SELECT UserId FROM deleted) 
         ORDER BY wu.DateAdded ASC) AS NewOwnerId
    FROM Wishlists w
    INNER JOIN deleted d ON w.OwnerId = d.UserId;
    OPEN wishlist_cursor;
    FETCH NEXT FROM wishlist_cursor INTO @WishlistId, @NewOwnerId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @NewOwnerId IS NOT NULL
        BEGIN
            -- Call the stored procedure to transfer ownership
            EXEC p_TransferWishlistOwnership @WishlistId = @WishlistId, @NewOwnerId = @NewOwnerId;
        END
        ELSE
        BEGIN
            -- No editor found, delete the wishlist and related child records
            DELETE FROM WishlistGames WHERE WishlistId = @WishlistId;
            DELETE FROM WishlistUsers WHERE WishlistId = @WishlistId;
            DELETE FROM Wishlists WHERE WishlistId = @WishlistId;
        END
        FETCH NEXT FROM wishlist_cursor INTO @WishlistId, @NewOwnerId;
    END

    CLOSE wishlist_cursor;
    DEALLOCATE wishlist_cursor;
    -- Finally, actually delete the User(s)
    DELETE u
    FROM Users u
    INNER JOIN deleted d ON u.UserId = d.UserId;
END;
GO

-- TEST tr_User_Delete_Change_Wishlist_Owner & VERIFY
BEGIN TRY
    -- Delete User 1 (Owner of Wishlist 1). User 2 has edit permissions, so they should become the owner.
    DELETE FROM Users WHERE UserId = 1; 
    PRINT '--- Verification for tr_User_Delete_Change_Wishlist_Owner ---';
    SELECT WishlistId, OwnerId AS [NewOwnerId] FROM Wishlists WHERE WishlistId = 1; -- Should show OwnerId = 2
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO


-- tr_DeleteUserImage: Deletes the associated UserImage when a user is deleted
CREATE OR ALTER TRIGGER tr_DeleteUserImage
    ON Users
    AFTER DELETE
AS BEGIN
    SET NOCOUNT ON;
    DELETE ui
    FROM UserImages ui
    INNER JOIN deleted d ON ui.UserImageID = d.UserImageId
    -- Add an extra check to ensure multiple users aren't somehow sharing the same image ID
    WHERE d.UserImageId IS NOT NULL 
      AND NOT EXISTS (
          SELECT 1 
          FROM Users u 
          WHERE u.UserImageId = ui.UserImageID
      );
END;
GO

-- TEST tr_DeleteUserImage & VERIFY
BEGIN TRY
    -- Insert a dummy image, associate with a user, then delete to verify
    INSERT INTO UserImages (UserImageData) VALUES (0x1234);
    DECLARE @ImageId INT = SCOPE_IDENTITY();
    
    INSERT INTO Users (Username, UserEmail, UserImageId) VALUES ('ImageDeleteTest', 'imgdel@test.local', @ImageId);
    DECLARE @UserId INT = SCOPE_IDENTITY();
    
    DELETE FROM Users WHERE UserId = @UserId;
    
    SELECT UserImageID FROM UserImages WHERE UserImageID = @ImageId; -- Should be empty
END TRY BEGIN CATCH PRINT 'Error: ' + ERROR_MESSAGE() END CATCH;
GO


---------------------------------------------
-- 3. Create Functions (5 Functions)
---------------------------------------------
-- Calculates the final price of a single game at a specific store by applying the DiscountPercent to the DefaultPrice.
CREATE OR ALTER FUNCTION dbo.fn_GetDiscountPrice (
    @GameId INT,
    @StoreId INT
)
RETURNS DECIMAL(10, 2)
AS BEGIN
    DECLARE @FinalPrice DECIMAL(10, 2);
    
    SELECT @FinalPrice = DefaultPrice * (1.00 - (DiscountPercent / 100.00))
    FROM dbo.GamePrices
    WHERE GameId = @GameId 
      AND StoreId = @StoreId;
    RETURN ISNULL(@FinalPrice, 0.00);
END;
GO

-- TEST fn_GetDiscountPrice & VERIFY
PRINT '--- Verification for fn_GetDiscountPrice ---';
-- Game 1 Store 1 has default price 59.99, discount 10.00% -> expect 53.99
SELECT dbo.fn_GetDiscountPrice(1, 1) AS [DiscountedPrice_Game1_Store1];
GO

-- Aggregates the standard DefaultPrice for all games currently added to a specific wishlist, using the cheapest available store default price.
CREATE OR ALTER FUNCTION dbo.fn_GetWishlistTotalPrice (
    @WishlistId INT
)
RETURNS DECIMAL(10, 2)
AS BEGIN
    DECLARE @TotalPrice DECIMAL(10, 2);
    
    SELECT @TotalPrice = SUM(CheapestPrice)
    FROM (
        SELECT MIN(gp.DefaultPrice) AS CheapestPrice
        FROM dbo.WishlistGames wg
        INNER JOIN dbo.GamePrices gp ON wg.GameId = gp.GameId
        WHERE wg.WishlistId = @WishlistId
        GROUP BY wg.GameId
    ) AS MinStorePrices;

    RETURN ISNULL(@TotalPrice, 0.00);
END;
GO

-- TEST fn_GetWishlistTotalPrice & VERIFY
-- Wishlist 3 has Game 1. Game 1 cheapest default price is 59.99.
SELECT dbo.fn_GetWishlistTotalPrice(3) AS [Wishlist3_TotalPrice];
GO


-- Aggregates the final discounted prices for all games in a specific wishlist to show the current actual cost to purchase the entire list.
CREATE OR ALTER FUNCTION dbo.fn_GetWishlistTotalPriceAfterDiscounts (
    @WishlistId INT
)
RETURNS DECIMAL(10, 2)
AS BEGIN
    DECLARE @TotalDiscountedPrice DECIMAL(10, 2);
    
    SELECT @TotalDiscountedPrice = SUM(CheapestDiscountedPrice)
    FROM (
        -- Convert DiscountPercent into a multiplier (e.g. 10.00% discount becomes a 0.90 multiplier)
        SELECT MIN(gp.DefaultPrice * (1.00 - (gp.DiscountPercent / 100.00))) AS CheapestDiscountedPrice
        FROM dbo.WishlistGames wg
        INNER JOIN dbo.GamePrices gp ON wg.GameId = gp.GameId
        WHERE wg.WishlistId = @WishlistId
        GROUP BY wg.GameId
    ) AS MinStoreDiscounts;

    RETURN ISNULL(@TotalDiscountedPrice, 0.00);
END;
GO

-- TEST fn_GetWishlistTotalPriceAfterDiscounts & VERIFY
PRINT '--- Verification for fn_GetWishlistTotalPriceAfterDiscounts ---';
-- Wishlist 3 has Game 1. Cheapest discounted price is 53.99.
SELECT dbo.fn_GetWishlistTotalPriceAfterDiscounts(3) AS [Wishlist3_TotalPriceAfterDiscounts];
GO


-- Calculates the total dollar amount saved (Total Default Price minus Total Discounted Price) for all games in a specific wishlist.
CREATE OR ALTER FUNCTION dbo.fn_GetWishlistTotalDiscount (
    @WishlistId INT
)
RETURNS DECIMAL(10, 2)
AS BEGIN
    DECLARE @TotalSaved DECIMAL(10, 2);
    
    -- Utilizes the previous functions to calculate the difference
    SET @TotalSaved = dbo.fn_GetWishlistTotalPrice(@WishlistId) - dbo.fn_GetWishlistTotalPriceAfterDiscounts(@WishlistId);
    
    RETURN ISNULL(@TotalSaved, 0.00);
END;
GO

-- TEST fn_GetWishlistTotalDiscount & VERIFY
-- Wishlist 3: 59.99 - 53.99 = 6.00
SELECT dbo.fn_GetWishlistTotalDiscount(3) AS [Wishlist3_TotalDiscount];
GO


-- Returns an integer representing the total number of games associated with a specific WishlistId.
CREATE OR ALTER FUNCTION dbo.fn_GetWishlistGameCount (
    @WishlistId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @GameCount INT;
    
    SELECT @GameCount = COUNT(*)
    FROM dbo.WishlistGames
    WHERE WishlistId = @WishlistId;
    
    RETURN ISNULL(@GameCount, 0);
END;
GO

-- TEST fn_GetWishlistGameCount & VERIFYf
-- Wishlist 3 has 1 game (GameId = 1).
SELECT dbo.fn_GetWishlistGameCount(3) AS [Wishlist3_GameCount];
GO
