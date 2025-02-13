#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
TEMPLATES_DIR="$PROJECT_PATH/templates"
LIB_DIR="$PROJECT_PATH/lib"

# Function to create feature structure
create_feature() {
    local feature_name=$1
    local feature_dir="$LIB_DIR/features/$feature_name"
    
    log_info "Creating feature: $feature_name"
    
    # Create feature directory structure
    mkdir -p "$feature_dir"/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}
    
    # Generate data layer
    cat > "$feature_dir/data/models/${feature_name}_model.dart" <<EOF
import '../domain/entities/${feature_name}.dart';

class ${feature_name^}Model extends ${feature_name^} {
  const ${feature_name^}Model({
    required String id,
  }) : super(id: id);

  factory ${feature_name^}Model.fromJson(Map<String, dynamic> json) {
    return ${feature_name^}Model(
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
EOF
    
    cat > "$feature_dir/data/datasources/${feature_name}_remote_datasource.dart" <<EOF
abstract class ${feature_name^}RemoteDataSource {
  Future<void> getData();
}

class ${feature_name^}RemoteDataSourceImpl implements ${feature_name^}RemoteDataSource {
  @override
  Future<void> getData() async {
    // TODO: implement getData
  }
}
EOF
    
    cat > "$feature_dir/data/repositories/${feature_name}_repository_impl.dart" <<EOF
import '../../domain/repositories/${feature_name}_repository.dart';

class ${feature_name^}RepositoryImpl implements ${feature_name^}Repository {
  final ${feature_name^}RemoteDataSource remoteDataSource;

  ${feature_name^}RepositoryImpl(this.remoteDataSource);

  @override
  Future<void> getData() async {
    // TODO: implement getData
  }
}
EOF
    
    # Generate domain layer
    cat > "$feature_dir/domain/entities/${feature_name}.dart" <<EOF
class ${feature_name^} {
  final String id;

  const ${feature_name^}({
    required this.id,
  });
}
EOF
    
    cat > "$feature_dir/domain/repositories/${feature_name}_repository.dart" <<EOF
abstract class ${feature_name^}Repository {
  Future<void> getData();
}
EOF
    
    cat > "$feature_dir/domain/usecases/get_${feature_name}_usecase.dart" <<EOF
import '../repositories/${feature_name}_repository.dart';

class Get${feature_name^}UseCase {
  final ${feature_name^}Repository repository;

  Get${feature_name^}UseCase(this.repository);

  Future<void> execute() async {
    return repository.getData();
  }
}
EOF
    
    # Generate presentation layer
    cat > "$feature_dir/presentation/bloc/${feature_name}_bloc.dart" <<EOF
import 'package:flutter_bloc/flutter_bloc.dart';

part '${feature_name}_event.dart';
part '${feature_name}_state.dart';

class ${feature_name^}Bloc extends Bloc<${feature_name^}Event, ${feature_name^}State> {
  final Get${feature_name^}UseCase get${feature_name^}UseCase;

  ${feature_name^}Bloc(this.get${feature_name^}UseCase) : super(${feature_name^}Initial()) {
    on<Get${feature_name^}Data>(_onGet${feature_name^}Data);
  }

  Future<void> _onGet${feature_name^}Data(
    Get${feature_name^}Data event,
    Emitter<${feature_name^}State> emit,
  ) async {
    emit(${feature_name^}Loading());
    try {
      await get${feature_name^}UseCase.execute();
      emit(${feature_name^}Loaded());
    } catch (e) {
      emit(${feature_name^}Error(e.toString()));
    }
  }
}
EOF
    
    cat > "$feature_dir/presentation/bloc/${feature_name}_event.dart" <<EOF
part of '${feature_name}_bloc.dart';

abstract class ${feature_name^}Event {}

class Get${feature_name^}Data extends ${feature_name^}Event {}
EOF
    
    cat > "$feature_dir/presentation/bloc/${feature_name}_state.dart" <<EOF
part of '${feature_name}_bloc.dart';

abstract class ${feature_name^}State {}

class ${feature_name^}Initial extends ${feature_name^}State {}

class ${feature_name^}Loading extends ${feature_name^}State {}

class ${feature_name^}Loaded extends ${feature_name^}State {}

class ${feature_name^}Error extends ${feature_name^}State {
  final String message;

  ${feature_name^}Error(this.message);
}
EOF
    
    cat > "$feature_dir/presentation/pages/${feature_name}_page.dart" <<EOF
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${feature_name}_bloc.dart';

class ${feature_name^}Page extends StatelessWidget {
  const ${feature_name^}Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ${feature_name^}Bloc(
        // TODO: Inject dependencies
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${feature_name^}'),
        ),
        body: BlocBuilder<${feature_name^}Bloc, ${feature_name^}State>(
          builder: (context, state) {
            if (state is ${feature_name^}Loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ${feature_name^}Loaded) {
              return const Center(child: Text('Loaded'));
            } else if (state is ${feature_name^}Error) {
              return Center(child: Text(state.message));
            }
            return const Center(child: Text('Initial'));
          },
        ),
      ),
    );
  }
}
EOF
    
    log_success "Feature $feature_name created successfully"
}

# Function to create service
create_service() {
    local service_name=$1
    local service_dir="$LIB_DIR/core/services"
    
    log_info "Creating service: $service_name"
    
    mkdir -p "$service_dir"
    
    cat > "$service_dir/${service_name}_service.dart" <<EOF
abstract class ${service_name^}Service {
  Future<void> initialize();
}

class ${service_name^}ServiceImpl implements ${service_name^}Service {
  @override
  Future<void> initialize() async {
    // TODO: implement initialize
  }
}
EOF
    
    log_success "Service $service_name created successfully"
}

# Function to create repository
create_repository() {
    local repo_name=$1
    local repo_dir="$LIB_DIR/core/repositories"
    
    log_info "Creating repository: $repo_name"
    
    mkdir -p "$repo_dir"
    
    cat > "$repo_dir/${repo_name}_repository.dart" <<EOF
abstract class ${repo_name^}Repository {
  Future<void> getData();
  Future<void> saveData();
}

class ${repo_name^}RepositoryImpl implements ${repo_name^}Repository {
  @override
  Future<void> getData() async {
    // TODO: implement getData
  }

  @override
  Future<void> saveData() async {
    // TODO: implement saveData
  }
}
EOF
    
    log_success "Repository $repo_name created successfully"
}

# Function to create dependency injection
create_di() {
    log_info "Creating dependency injection..."
    
    local di_dir="$LIB_DIR/core/di"
    mkdir -p "$di_dir"
    
    cat > "$di_dir/injection.dart" <<EOF
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Services
  
  // Repositories
  
  // UseCases
  
  // BLoCs
}
EOF
    
    log_success "Dependency injection created successfully"
}

# Main function
main() {
    if [ $# -lt 2 ]; then
        log_error "Usage: $0 <type> <name>"
        log_error "Types: feature, service, repository, di"
        exit 1
    fi
    
    local type=$1
    local name=$2
    
    case "$type" in
        "feature")
            create_feature "$name"
            ;;
        "service")
            create_service "$name"
            ;;
        "repository")
            create_repository "$name"
            ;;
        "di")
            create_di
            ;;
        *)
            log_error "Invalid type: $type"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 