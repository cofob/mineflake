use anyhow::Result;
use std::{
	env::vars,
	fs::{self, copy, create_dir_all, set_permissions, File},
	io::Write,
	path::{Path, PathBuf},
};

use crate::{
	structures::common::{FileMapping, ServerState},
	utils::merge::merge_json,
};

/// A type of file to link
#[derive(Debug)]
pub enum LinkTypes {
	/// Copy a file from one path to another
	Copy(FileMapping),

	/// Write a raw string to a file
	///
	/// The first argument is the content, the second is the path.
	/// Used for writing config files.
	Raw(String, PathBuf),

	/// Merge a JSON file with another
	MergeJSON(serde_json::Value, PathBuf),

	/// Merge a YAML file with another
	MergeYAML(serde_yaml::Value, PathBuf),
}

impl LinkTypes {
	/// Get the path of the file to link
	pub fn get_path(&self) -> PathBuf {
		match &self {
			Self::Copy(f) => f.1.clone(),
			Self::Raw(_, p) => p.clone(),
			Self::MergeJSON(_, p) => p.clone(),
			Self::MergeYAML(_, p) => p.clone(),
		}
	}
}

/// Write a file to the given path, replacing {{VAR}} with the value of the environment variable VAR
fn write_file(path: &PathBuf, content: &str) -> Result<()> {
	let mut file = File::create(path)?;
	let mut content = content.to_string();
	for var in vars() {
		// {{VAR}}
		content = content.replace(&format!("{{{{{}}}}}", var.0), &var.1);
	}
	file.write_all(content.as_bytes())?;
	Ok(())
}

/// Link files to the given directory
pub fn link_files(directory: &Path, files: &Vec<LinkTypes>) -> Result<()> {
	for file in files {
		debug!("Linking {:?}", file);
		let dest_path = directory.join(file.get_path());
		let parent = dest_path.parent().unwrap();
		create_dir_all(parent)?;
		match file {
			LinkTypes::Copy(mapping) => {
				copy(&mapping.0, &dest_path)?;
				let mut perms = fs::metadata(&dest_path)?.permissions();
				perms.set_readonly(false);
				set_permissions(&dest_path, perms)?;
			}
			LinkTypes::Raw(content, _) => {
				write_file(&dest_path, content)?;
			}
			LinkTypes::MergeJSON(content, _) => {
				let mut new_content = serde_json::from_str(&std::fs::read_to_string(&dest_path)?)
					.expect("Failed to parse JSON file");
				merge_json(&mut new_content, content);
				write_file(&dest_path, &serde_json::to_string(&new_content)?)?;
			}
			LinkTypes::MergeYAML(content, _) => {
				let mut new_content: serde_json::Value = serde_json::to_value(
					serde_yaml::from_str::<serde_yaml::Value>(&std::fs::read_to_string(
						&dest_path,
					)?)
					.expect("Failed to parse YAML file"),
				)?;
				let content = &serde_json::to_value(content)?;
				merge_json(&mut new_content, content);
				write_file(&dest_path, &serde_yaml::to_string(&new_content)?)?;
			}
		}
	}

	Ok(())
}

/// Diff two server states and return a list of paths that are in the previous state but not in the current state
///
/// This is used to remove files that are no longer needed.
pub fn diff_states(curr_state: &ServerState, prev_state: &ServerState) -> Vec<PathBuf> {
	let mut out = Vec::new();
	for prev_path in &prev_state.paths {
		let mut collision = false;
		for curr_path in &curr_state.paths {
			if prev_path == curr_path {
				collision = true;
				break;
			}
		}
		if !collision {
			out.push(prev_path.clone());
		}
	}
	out
}

/// Remove a file and its parent directories if they are empty.
///
/// This function is recursive and will remove all empty parent directories.
/// This is potentially dangerous, because it will remove directories upper than directory,
/// so use with caution.
pub fn remove_with_parent(path: &PathBuf) {
	debug!("Removing file {:?}", &path);
	let _ = std::fs::remove_file(path);
	// Delete parent directory if it is empty
	let mut parent = path.clone();
	loop {
		parent = match parent.parent() {
			Some(parent) => parent.to_path_buf(),
			None => break,
		};
		let read_dir = match parent.read_dir() {
			Ok(read_dir) => read_dir,
			Err(_) => break,
		};
		if read_dir.count() == 0 {
			debug!("Removing empty directory {:?}", parent);
			let _ = std::fs::remove_dir(parent.clone());
		} else {
			break;
		}
	}
}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn test_diff_states() {
		let curr_state = ServerState {
			paths: vec![
				PathBuf::from("a"),
				PathBuf::from("b"),
				PathBuf::from("c"),
				PathBuf::from("d"),
			],
		};
		let prev_state = ServerState {
			paths: vec![
				PathBuf::from("a"),
				PathBuf::from("b"),
				PathBuf::from("c"),
				PathBuf::from("d"),
				PathBuf::from("e"),
				PathBuf::from("f"),
			],
		};
		let diff = diff_states(&curr_state, &prev_state);
		assert_eq!(diff, vec![PathBuf::from("e"), PathBuf::from("f")]);
	}

	#[test]
	fn test_diff_states_empty() {
		let curr_state = ServerState {
			paths: vec![
				PathBuf::from("a"),
				PathBuf::from("b"),
				PathBuf::from("c"),
				PathBuf::from("d"),
			],
		};
		let prev_state = ServerState {
			paths: vec![
				PathBuf::from("a"),
				PathBuf::from("b"),
				PathBuf::from("c"),
				PathBuf::from("d"),
			],
		};
		let diff = diff_states(&curr_state, &prev_state);
		assert_eq!(diff, Vec::<PathBuf>::new());
	}
}
