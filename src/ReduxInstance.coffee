import { BoundInstance } from 'ormojo'

# Nonce class to tag ReduxInstances in case the user wants to discern them from other instances.
export default class ReduxInstance extends BoundInstance
