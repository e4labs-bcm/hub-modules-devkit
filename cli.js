#!/usr/bin/env node

/**
 * Hub.app DevKit CLI
 * Command-line interface for creating and managing Hub.app modules
 */

const { program } = require('commander');
const chalk = require('chalk');
const packageJson = require('./package.json');

// Import commands
const createModule = require('./lib/create-module');
const installModule = require('./lib/install-module');
const { update } = require('./lib/update');
const { rollback } = require('./lib/rollback');
const { checkUpdates, autoCheckUpdates } = require('./lib/check-updates');

// ============================================================================
// CLI Configuration
// ============================================================================

program
  .name('hubapp-devkit')
  .description('Development kit for creating Hub.app modules in minutes')
  .version(packageJson.version);

// ============================================================================
// Commands
// ============================================================================

/**
 * create - Cria um novo módulo
 */
program
  .command('create <slug> <title> [icon]')
  .description('Cria um novo módulo Hub.app')
  .action(async (slug, title, icon = 'Package') => {
    try {
      await createModule([slug, title, icon]);
    } catch (error) {
      console.error(chalk.red('✗'), `Erro: ${error.message}`);
      process.exit(1);
    }
  });

/**
 * install - Instala um módulo no Hub.app
 */
program
  .command('install <slug> <title> <icon> [tenant-id]')
  .description('Instala um módulo no Hub.app (banco + API routes)')
  .action(async (slug, title, icon, tenantId) => {
    try {
      await installModule([slug, title, icon, tenantId]);
    } catch (error) {
      console.error(chalk.red('✗'), `Erro: ${error.message}`);
      process.exit(1);
    }
  });

/**
 * update - Atualiza o DevKit para a versão mais recente
 */
program
  .command('update')
  .description('Atualiza o DevKit para a versão mais recente')
  .action(async () => {
    try {
      await update();
    } catch (error) {
      console.error(chalk.red('✗'), `Erro: ${error.message}`);
      process.exit(1);
    }
  });

/**
 * rollback - Volta para uma versão anterior
 */
program
  .command('rollback')
  .description('Faz rollback para uma versão anterior')
  .action(async () => {
    try {
      await rollback();
    } catch (error) {
      console.error(chalk.red('✗'), `Erro: ${error.message}`);
      process.exit(1);
    }
  });

/**
 * check-updates - Verifica se há atualizações disponíveis
 */
program
  .command('check-updates')
  .description('Verifica se há atualizações disponíveis')
  .action(async () => {
    try {
      await checkUpdates(false);
    } catch (error) {
      console.error(chalk.red('✗'), `Erro: ${error.message}`);
      process.exit(1);
    }
  });

/**
 * help - Ajuda customizada
 */
program.on('--help', () => {
  console.log('');
  console.log('Exemplos:');
  console.log('');
  console.log('  # Criar módulo de Tarefas');
  console.log('  $ hubapp-devkit create tarefas "Tarefas" ListTodo');
  console.log('');
  console.log('  # Instalar módulo no Hub.app');
  console.log('  $ cd ~/hub-app-nextjs');
  console.log('  $ hubapp-devkit install tarefas "Tarefas" ListTodo');
  console.log('');
  console.log('  # Com tenant específico');
  console.log('  $ hubapp-devkit install tarefas "Tarefas" ListTodo a01b75e2-233b-40c2-801b-0e4a7e2a4055');
  console.log('');
  console.log('Documentação:');
  console.log('  https://github.com/e4labs-bcm/hub-modules-devkit');
  console.log('');
});

// ============================================================================
// Auto-check for updates (non-blocking, background)
// ============================================================================

// Executa auto-check de forma não bloqueante
// Apenas notifica se há atualização disponível (1x por dia, cache 24h)
setImmediate(async () => {
  try {
    const hasUpdate = await autoCheckUpdates();
    if (hasUpdate) {
      console.log(chalk.blue('\nℹ️  Nova versão disponível. Execute: hubapp-devkit update\n'));
    }
  } catch (error) {
    // Fail silently - auto-check não deve quebrar o CLI
  }
});

// ============================================================================
// Parse Arguments
// ============================================================================

program.parse(process.argv);

// Mostrar help se nenhum comando foi fornecido
if (!process.argv.slice(2).length) {
  program.outputHelp();
}
