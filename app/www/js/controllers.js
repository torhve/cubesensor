angular.module('starter.controllers', [])

.controller('StoveCtrl', function($scope, $http, $interval, CubeService) {
    CubeService.setId('000D6F0003E16037');
    CubeService.refresh();
    $scope.current = CubeService.current();
    $scope.onRefresh = function() {
        CubeService.refresh();
    }
})

.controller('SoveCtrl', function($scope, $http, CubeService) {
    CubeService.setId('000D6F0003117ED0');
    CubeService.refresh();
    $scope.current = CubeService.current();
    $scope.onRefresh = function() {
        CubeService.refresh();
    }
})

.controller('FriendDetailCtrl', function($scope, $stateParams, Friends) {
  $scope.friend = Friends.get($stateParams.friendId);
})

.controller('AccountCtrl', function($scope) {
});
