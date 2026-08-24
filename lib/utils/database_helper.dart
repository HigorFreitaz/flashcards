import '../models/app_user.dart';

class DatabaseHelper {
  AppUser? login(AppUser user){
    if(user.email == 'thomas.vaz@gmail.com' && user.password == 'thomas34'){
      return AppUser(name: 'Thomas Jefersson Vaz', email: 'thomas.vaz@gmail.com', password: 'thomas34');
    }
    return null;
  }

  AppUser? signup(AppUser user){
    if(user.email == 'thomas.vaz@gmail.com'){
      return null;
    }
    return AppUser(name: user.name, email: user.email, password: user.password);
  }

  void syncData(AppUser user){

  }


}