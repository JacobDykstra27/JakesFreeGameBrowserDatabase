### Jake’s Free Game Browser Database
The primary goal of this database is to store information on video game sales and giveaways including but not limited to game information, game price, game store, and a link to buy or get the game. The information will come from a third-party API and is being stored to lessen demand on the API by saving data for a couple hours before and only getting new information from the API when a user requests information that is out-dated. 
The secondary goal of this database is to allow users to save and share game wishlists with other users and allowing multiple users to edit or view wishlists created by other users. Users will be able to “friend” one another for easy sharing of wishlists.

### Context
This database will be accessed primarily from a mobile app developed for different clients. The goal of the mobile app is to show the user free games and games on sale and allow users to create a wishlist of games they want and share it with other users. 
A potential expansion of the app that may affect the database is the ability to save games as “owned” and view or compare owned games to other users.

### Business Rules 
Business Rules are the rules what dictate how the database will store data, what type of data can be stored, and how stored data is related to other stored data.

**Users may have many friends**

A user can have as many relationships to other users as they want. The relationship is called being friends.
Two users cannot be friends multiple times and a user cannot be friends with themselves.
Users can see their friends in the mobile app.

**Users may own/edit/view many wishlists**
A user may create and own as many wishlists as they want. 
An owner can add and remove viewers and editors of the wishlist.
The owner can be changed but the wishlist must always have an owner.
An editor or owner can add and remove games on the wishlist.
A viewer can only view the contents of the wishlist

**Wishlists must have one owner (user)**
A user who creates a wishlist becomes its owner.
Owners have the same permissions as editors but can also add and remove other users permissions for the wishlist.

**Wishlists may have many editors/viewers (users)**
A wishlist owner can give any number of other users permission to edit or view the wishlist.
Wishlist viewers and editors may see what games are on the wishlist.
An editor can also add and remove games from the wishlist.

**Wishlists may have many games**
A wishlist may have any number of games on it. And a game can be on any number of wishlists.

**Games may have many prices**
Games may be sold on multiple stores, and each store can have a different price.
To store this data each game can have multiple entries on the GamePrice table. Each entry must have a store listed for where the game is on sale and a link for the game on that store front.

**Games may have many genres**
A game may have multiple genres like FPS and Horror or Strategy and Farming.

### Tables
A table of data is most easily understood by comparing it to a spread sheet with columns and rows of data. Each bolded word is the name of a table and each bullet point below it is a column of data in the spread sheet. The abbreviation **PK** means **Primary Key**. A Primary key is unique to each row of data and is used to identify it. The abbreviation **FK** stands for **Forign Key** and means that column will have PK from a different table. For example the Wishlist Table’s OwnerId is a FK column and would store a PK from the Users table. The abbreviation **CK** stands for **Composite Key**. A composite key is when two or more columns form a single PK. For example, when two users are listed as friends in the Friends table, both of their UserIds combined make a single unique identifier called a CK.

**Users**
- UserId (PK)
- Username
- UserEmail
- UserDescription
- UserCreationDate
- UserSocialContact
- UserImage

**Wishlists**
- WishlistId (PK)
- OwnerId (FK)
- WishlistName
- WishlistDescription
- WishlistCreationDate

**Genres**
- GenreID (PK)
- GenreName
- GenreDescription

**Stores**
- StoreId (PK)
- StoreName
- StoreLink

**Games**
- GameId (PK)
- GameName
- GameDescription
- GameImage
- LastUpdateDate

**Friends**
- UserId (CK)
- FriendId (CK)
- FriendDate

**WishlistUsers**
- WishlistId (CK)
- UserId (CK)
- Permission
- DateAdded

**GamePrices**
- GameId (CK)
- Store (CK)
- DefaultPrice
- DiscountPercent
- GameLink

**WishlistGames**
- WishlistId (CK)
- GameId (CK)
- DateAdded
- UserAdded

**GameGenres**
- GameID (CK)
- GenreID (CK)

### Crow’s Foot Entity Relationship Diagram 
The Crow’s Foot ERD is a way to visualize tables and how they relate to one another. The ERD has all the same tables and columns as above but also shows what tables are related and how. PK and FK are both represented here but CK is represented by the combination of PK and FK. This Database is comprised of only “One to Many” relationships and a relationship is visualized by the lines and symbols connecting each table. The two short lines intersecting the longer line is a “one and only one” symbol. This Means that the PK for a row of data on that table will only be listed one time. The circle with 3 lines coming out from it is what gives the ERD its name “crow’s foot”. That symbol means “zero to many”. The PK mentioned before can be listed in this table zero or many times as a FK. For example the Users table is related to the Friends table. The symbol on the Users table is “one and only one” because each user gets a Unique UserId that will only be in that table one time. The symbol on the Friends table is “zero or many” because a user’s UserId will be in that table one time for every friend they have. If the user has zero friends then their id will not be in that table, and if they have many friends then it will be in the table many times.


### Stored Procedures
**p_CreateWishlist** Safely creates a new wishlist for a specific user. It verifies the user exists and prevents the creation of duplicate wishlist names.

**p_AddGame** Inserts a new game into the database along with its associated details, such as description and genre.

**p_AddUser** Registers a new user in the system. It guarantees that the requested username and email are strictly unique before creating the record.

**p_AddFriend Establishes** a bidirectional friendship between two users. It validates that both users exist and ensures they aren't already friends.

**p_AddGameToWishlist** Saves a specific game to a user's wishlist. It ensures the game, user, and wishlist exist while preventing duplicate game entries on the same list.

**p_RollbackWishlistOwner** Reverts the ownership of a wishlist back to its previously archived owner.

**p_RollbackAccountChanges** Restores a user's profile information to its most recently archived state.

**p_TransferWishlistOwnership** Safely reassigns ownership of a wishlist from one user to another using a transaction to ensure data integrity.

**p_RemoveGameFromWishlist** Deletes a specific game entry from a user's wishlist. 

**p_RemoveFriend** Severs an existing friendship mapping between two users, safely handling the relationship regardless of who initiated it. 

**p_RemoveWishlistUser** Revokes a collaborator's (editor or viewer) granted permissions to a specific wishlist. 

**p_PurgeOldArchives** Cleans up database storage by permanently deleting archive records (users, wishlists, and game updates) older than one year.

### Triggers 
**tr_ArchiveWishlistOwner** Automatically saves the previous owner's ID into an archive table whenever a wishlist's ownership is updated.

**tr_ArchiveUserEdits** Automatically logs a user's previous profile details into an archive table right before their profile is modified.

**tr_ArchiveGameUpdates** Tracks when games are inserted or updated by logging the event and the specific affected games into the API update archive tables.

**tr_User_Delete_Change_Wishlist_Owner** Intercepts user deletions to automatically transfer their wishlists to the oldest existing editor. If no editors exist, it cascades the deletion to the wishlists.

**tr_DeleteUserImage** Intercepts a user deletion to automatically purge associated UserImage entry before deleting the user. 

### Functions
**fn_GetDiscountPrice** Calculates the final price of a specific game at a specific store by applying the store's current discount percentage to the standard price.

**fn_GetWishlistTotalPrice** Calculates the total base cost of a wishlist by summing up the cheapest standard retail price available across all stores for each game.

**fn_GetWishlistTotalPriceAfterDiscounts** Calculates the actual current cost of purchasing an entire wishlist by summing the cheapest discounted prices for each game.

**fn_GetWishlistTotalDiscount** Calculates the total dollar amount a user saves on an entire wishlist by comparing the standard retail prices against the currently available discounted prices.

**fn_GetWishlistGameCount** Returns the total count of games currently saved within a specific wishlist.
