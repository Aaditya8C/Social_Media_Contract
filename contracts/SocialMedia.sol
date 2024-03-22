// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SocialMedia {
    struct User {
        string username;
        string photoUrl;
        uint256 points;
        uint256 interactionTime;
        bool isLoggedIn;
    }

    struct Comment {
        bytes32 id;
        bytes32 postId;
        string owner;
        string content;
    }

    struct Post {
        bytes32 id;
        address owner;
        string contentType; // "text", "image", "video"
        string content;
        uint256 likes;
        uint256 timestamp;
    }

    struct PostWithOwner {
        bytes32 id;
        address owner;
        string ownerUsername;
        string ownerPhotoUrl;
        string contentType;
        string content;
        uint256 likes;
        uint256 timestamp;
        Comment[] comment;
    }

    mapping(address => User) public users;
    mapping(address => Post[]) public posts;
    mapping(bytes32 => Comment[]) public comments;
    address[] public userAddresses; // for storing all post ids

    // Event to log rewards
    event Reward(address indexed from, address indexed to, uint256 amount);

    // Users
    function createUser(
        string memory _username,
        string memory _photoUrl
    ) public {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(!users[msg.sender].isLoggedIn, "User already exists");

        users[msg.sender] = User({
            username: _username,
            photoUrl: _photoUrl,
            points: 0,
            interactionTime: block.timestamp,
            isLoggedIn: true
        });
        userAddresses.push(msg.sender);
    }

    function login() public {
        require(!users[msg.sender].isLoggedIn, "User already logged in");
        require(
            bytes(users[msg.sender].username).length > 0,
            "Please create user account"
        );
        users[msg.sender].isLoggedIn = true;
    }

    function logout() public {
        require(users[msg.sender].isLoggedIn, "User does not exists");
        users[msg.sender].isLoggedIn = false;
    }

    function getUserProfile(
        address _userAddress
    )
        public
        view
        returns (string memory, string memory, uint256, uint256, bool)
    {
        require(_userAddress != address(0), "Invalid address");
        require(
            users[_userAddress].isLoggedIn,
            "Please login to access your profile...."
        );

        User memory user = users[_userAddress];
        return (
            user.username,
            user.photoUrl,
            user.points,
            user.interactionTime,
            user.isLoggedIn
        );
    }

    function getUserPosts(
        address _userAddress
    ) public view returns (Post[] memory) {
        Post[] memory userPosts = posts[_userAddress];
        return userPosts;
    }

    //Posts
    function createPost(
        string memory _contentType,
        string memory _content
    ) public {
        require(users[msg.sender].isLoggedIn, "Please create user account");
        require(bytes(_contentType).length > 0, "Content type cannot be empty");
        require(bytes(_content).length > 0, "Content cannot be empty");

        bytes32 postId = keccak256(
            abi.encodePacked(block.timestamp, _content, msg.sender)
        );
        posts[msg.sender].push(
            Post({
                id: postId,
                owner: msg.sender,
                contentType: _contentType,
                content: _content,
                likes: 0,
                timestamp: block.timestamp
            })
        );

        // postKeys.push(postId);
    }

    // Function to like a post
    function likePost(bytes32 _postId, address userAddress) public {
        require(users[msg.sender].isLoggedIn, "Please create user account");
        // require(bytes(posts[_postId].content).length > 0, "Post does not exist");
        Post[] storage userPosts = posts[userAddress];
        for (uint i = 0; i < userPosts.length; i++) {
            if (userPosts[i].id == _postId) {
                userPosts[i].likes++;
                address owner = userPosts[i].owner;
                users[owner].points += 1; // Increase points for the owner
                emit Reward(msg.sender, owner, 1); // Emit event for reward
            }
        }
    }

    function getAllPosts() public view returns (PostWithOwner[] memory) {
        require(users[msg.sender].isLoggedIn, "Please create user account");

        uint256 totalPosts = 0;

        // Calculate the total number of posts
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            totalPosts += posts[userAddress].length;
        }

        // Initialize the response array
        PostWithOwner[] memory response = new PostWithOwner[](totalPosts);
        uint256 currentIndex = 0;

        // Iterate over all users and their posts
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            Post[] storage userPosts = posts[userAddress];

            for (uint256 j = 0; j < userPosts.length; j++) {
                Post storage post = userPosts[j];
                User storage postOwner = users[post.owner];
                Comment[] storage postComments = comments[post.id];

                response[currentIndex] = PostWithOwner({
                    id: post.id,
                    owner: post.owner,
                    ownerUsername: postOwner.username,
                    ownerPhotoUrl: postOwner.photoUrl,
                    contentType: post.contentType,
                    content: post.content,
                    likes: post.likes,
                    timestamp: post.timestamp,
                    comment: postComments
                });
                currentIndex++;
            }
        }

        return response;
    }

    function getPostDetails(
        bytes32 _postId
    ) public view returns (PostWithOwner[] memory) {
        require(users[msg.sender].isLoggedIn, "Please create user account");

        Post[] storage userPosts = posts[msg.sender];
        PostWithOwner[] memory response = new PostWithOwner[](1);

        for (uint256 i = 0; i < userPosts.length; i++) {
            if (userPosts[i].id == _postId) {
                Post storage post = userPosts[i];
                User storage postOwner = users[post.owner];
                Comment[] storage postComments = comments[post.id];

                response[0] = PostWithOwner({
                    id: post.id,
                    owner: post.owner,
                    ownerUsername: postOwner.username,
                    ownerPhotoUrl: postOwner.photoUrl,
                    contentType: post.contentType,
                    content: post.content,
                    likes: post.likes,
                    timestamp: post.timestamp,
                    comment: postComments
                });

                break; // Exit loop once the post is found
            }
        }
        return response;
    }

    // Function to add a comment to a post
    function addComment(
        bytes32 _postId,
        string memory _comment,
        string memory username
    ) public {
        require(bytes(_comment).length > 0, "Comment cannot be empty");

        bytes32 _commentId = keccak256(
            abi.encodePacked(block.timestamp, _comment, msg.sender)
        );

        Comment memory newComment = Comment({
            id: _commentId,
            postId: _postId,
            owner: username,
            content: _comment
        });
        comments[_postId].push(newComment);
    }

    // Reward Managment
    function rewardEngagement(address payable _to) public payable {
        require(_to != address(0), "Invalid recipient address");
        require(msg.value > 0, "Invalid amount");
        _to.transfer(msg.value);
    }
}
