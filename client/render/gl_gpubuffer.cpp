/*
gl_gpubuffer.cpp - OpenGL Buffer object wrapper
Copyright (C) 2026

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
*/

#include "gl_local.h"
#include "gl_debug_scope.h"
#include "gl_gpubuffer.h"

GLenum BufferTypeToTarget(BufferType type)
{
	switch (type)
	{
	case BT_VERTEX:
		return GL_ARRAY_BUFFER_ARB;

	case BT_INDEX:
		return GL_ELEMENT_ARRAY_BUFFER_ARB;
	
	default:
		break;
	};

	ASSERT(0 && "Unknown buffer type");
	return 0;
}

GLenum BufferAccessToAccess(BufferAccess access)
{
	switch (access)
	{
	case BA_READ_ONLY:
		return GL_READ_ONLY_ARB;

	case BA_WRITE_ONLY:
		return GL_WRITE_ONLY_ARB;

	case BA_READ_WRITE:
		return GL_READ_WRITE_ARB;

	default:
		break;
	}

	ASSERT(0 && "Unknown buffer access");
	return 0;
}

CGPUBuffer::CGPUBuffer(BufferType type, void* data, size_t size, bool isStream /*= false*/)
{
	m_type = type;
	m_target = BufferTypeToTarget(m_type);
	m_isStream = isStream;
	m_size = size;

	pglGenBuffersARB(1, &m_buffer);
	pglBindBufferARB(m_target, m_buffer);

	GL_DEBUG_SCOPE();

	pglBufferDataARB(m_target, size, data, isStream ? GL_DYNAMIC_DRAW_ARB : GL_STATIC_DRAW_ARB);
	pglBindBufferARB(m_target, 0);
}

CGPUBuffer::~CGPUBuffer()
{
	pglDeleteBuffersARB(1, &m_buffer);
}

void CGPUBuffer::Bind()
{
	pglBindBufferARB(m_target, m_buffer);
}

void* CGPUBuffer::MapBuffer(BufferAccess access)
{
	Bind();

	void* ptr = pglMapBufferARB(m_target, BufferAccessToAccess(access));

	GL_DEBUG_SCOPE();

	return ptr;
}

void CGPUBuffer::UnmapBuffer()
{
	Bind();

	pglUnmapBufferARB(m_target);
}

void CGPUBuffer::UpdateBuffer(void* data, size_t size)
{
	ASSERT(m_isStream && "Trying to update static buffer.");

	// Clear GL errors
	pglGetError();

	// Bind buffer
	Bind();

	GL_DEBUG_SCOPE();

	pglBufferDataARB(m_target, size, data, GL_DYNAMIC_DRAW_ARB);

	GLenum error = pglGetError();
	if (error == GL_OUT_OF_MEMORY)
	{
		HOST_ERROR("GPUBuffer::UpdateData: Out of memory! Couldn't allocate buffer with %u size", (unsigned)size);
		return;
	}

	m_size = size;
}
