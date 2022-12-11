#[macro_use]
extern crate log;

use std::{env::current_dir, path::PathBuf};

use clap::{Parser, Subcommand};
use mineflake::{
	self,
	structures::common::{Server, ServerConfig, ServerSpecificConfig},
};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
	#[command(subcommand)]
	command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
	/// Apply a configuration to directory.
	Apply {
		/// Configuration to apply.
		#[clap(default_value = "mineflake.yml", long = "config", short = 'c')]
		config: PathBuf,
		/// Configuration to apply.
		#[clap(default_value = "false", long = "run", short = 'r')]
		run: bool,
		/// Directory to apply configuration. If not specified, the current directory will be used.
		directory: Option<PathBuf>,
	},
	/// Run server.
	Run {
		/// Configuration to apply.
		#[clap(default_value = "mineflake.yml", long = "config", short = 'c')]
		config: PathBuf,
		/// Directory to apply configuration. If not specified, the current directory will be used.
		directory: Option<PathBuf>,
	},
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
	mineflake::utils::initialize_logger();

	const VERSION: &'static str = env!("CARGO_PKG_VERSION");
	debug!("Running mineflake v{}", VERSION);

	let cli = Cli::parse();

	// You can check for the existence of subcommands, and if found use their
	// matches just as you would the top level cmd
	match &cli.command {
		Some(Commands::Apply {
			config,
			directory,
			run,
		}) => {
			let config = ServerConfig::from(config.clone());
			let directory = match directory {
				Some(dir) => dir.clone(),
				None => current_dir()?,
			};
			match &config.server {
				ServerSpecificConfig::Spigot(spigot) => {
					spigot.prepare_directory(&config, &directory)?;
					if *run {
						spigot.run_server(&config, &directory)?;
					}
				}
			}
		}
		Some(Commands::Run { config, directory }) => {
			let config = ServerConfig::from(config.clone());
			let directory = match directory {
				Some(dir) => dir.clone(),
				None => current_dir()?,
			};
			match &config.server {
				ServerSpecificConfig::Spigot(spigot) => {
					spigot.run_server(&config, &directory)?;
				}
			}
		}
		None => {
			return Err("No subcommand was used. Use --help for more information.".into());
		}
	}

	Ok(())
}
