#!/bin/bash
# Script untuk membuat struktur direktori AURA+

# Core directories
mkdir -p lib/core/{config,theme,router,providers,services,utils,exceptions}

# Feature directories
mkdir -p lib/features/auth/{data/{datasources,repositories,models},domain/{entities,repositories,usecases,models},presentation/{providers,screens,widgets}}
mkdir -p lib/features/dashboard/{data/{datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/therapy/{data/{datasources,repositories,models},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/ar_engine/{data/{datasources,repositories,models},domain/{entities,repositories,usecases},presentation/{providers,widgets,controllers}}
mkdir -p lib/features/ai_recommendation/{data/{datasources,repositories,models},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/progress/{data/{datasources,repositories,models},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}
mkdir -p lib/features/settings/{data/{datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}

# Shared directories
mkdir -p lib/shared/{widgets/{common,navigation,therapy},models,constants}

# Asset directories
mkdir -p assets/{images/{logos,avatars,therapy,ui},icons/{therapy,navigation,system},animations/{lottie,rive},models/{ai,ml},audio/{sounds,music,voice},unity/{builds,assets},therapy_content/{vocabulary,verbal,aac}}

# Test directories
mkdir -p test/{unit/{core,features,shared},widget,integration}

# Unity directory
mkdir -p unity/AURA_AR_Engine/{Assets,ProjectSettings,Packages}
mkdir -p unity/builds

echo "Struktur direktori AURA+ berhasil dibuat!"
